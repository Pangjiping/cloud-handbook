<h1>1. 什么是httprouter</h1>
<p>较为流行的go web框架大多使用httprouter，或者是基于httprouter的变种对路由进行支持。</p>
<p>httprouter使用的是显式匹配，所以在路由设计的时候会存在一些路由冲突的问题：</p>
<pre class="language-bash"><code>GET /user/info/:name
GET /user/:id</code></pre>
<p>&nbsp;</p>
<p>上面这两个路由就会产生冲突，冲突的规则很简单，当两个路由是一样的HTTP方法和路由请求前缀，但是在某个位置出现了一个路由是wildcard(:id)，另一个路由是普通字符串(info)，就会发生路由冲突。</p>
<p>&nbsp;</p>
<p>除了支持路径中的wildcard之外，httprouter还可以支持 * 通配符，但是 * 开头的参数只能放在路由的结尾：</p>
<pre class="language-bash"><code>Pattern: /src/*filepath

/src/                        filepath = ""
/src/somefile.go             filepath = "somefile.go"
/src/subdir/somefile.go      filepath = "subdir/somefile.go"</code></pre>
<p>&nbsp;</p>
<p>其实稍微思考一下上面这两个限制，可以看出这是httprouter数据结构上所带来的问题，使用字典树进行匹配时会产生这样的冲突或者通配限制</p>
<p>除了正常情况下的路由支持，httprouter也支持对一些特殊情况下的回调函数进行定制，比如当404的时候：</p>
<pre class="language-go"><code>r := httprouter.New()
r.NotFound = http.HandlerFunc( func (w http.ResponseWriter, r *http.Request){
   w.Write([]byte( "oh no, not found" ))&nbsp;&nbsp;&nbsp;&nbsp; 
})</code></pre>
<p>　　</p>
<h1>2. httprouter原理</h1>
<p>httprouter使用的数据结构就是压缩字典树。</p>
<p>为什么使用压缩字典树？&mdash;&mdash;普通的字典树有个比较明显的缺点，就是每个字母都需要建立一个孩子节点，这样会导致字典树的层数比较深，压缩字典树相对好的平衡了字典树的优点和缺点，可以更好的用于前缀查询，典型的就是路由结构</p>
<p>典型的压缩字典树结构如下：</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326151841337-868486442.png" alt="" width="803" height="502" loading="lazy" /></p>
<p>&nbsp;</p>
<p>可以看到压缩字典树每个节点不只是一个字母，使用压缩字典树可以有效地减少树的层数，所以程序的局部性较好，从而对CPU友好</p>
<p>&nbsp;</p>
<h2>2.1 压缩字典树的创建过程</h2>
<p>我们现在想要设置这样的一组路由：</p>
<pre class="language-bash"><code>PUT /user/installations/:installation_id/repositories/:repository_id

GET /marketplace_listing/plans/
GET /marketplace_listing/plans/:id/accounts
GET /search
GET /status
GET /support

补充路由：
GET /marketplace_listing/plans/ohyes</code></pre>
<p>&nbsp;</p>
<p>在httprouter中，每一种方法都对应着一个压缩字典树，这些方法与压缩字典树以map的方式关联起来：</p>
<pre class="language-go"><code>type Router struct {
    // ...
    trees map [string]*node
    // ...
}</code></pre>
<p>&nbsp;</p>
<p>我们的第一个路由是：PUT /user/installations/:installation_id/repositories/:repository_id</p>
<p>当对一个http方法创建第一个路由的时候，会创建一个新的字典树，那么这个PUT请求所对应的字典树就是这样的：</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326152435954-1747556923.png" alt="" width="764" height="517" loading="lazy" /></p>
<p>&nbsp;</p>
<p>其中一些字段的释义为：</p>
<ul>
<li>path：当前节点对应的路径中的字符串</li>
<li>wildChild：子节点是否为参数节点，类似于:id</li>
<li>nType：当前节点类型：static--非根节点的普通字符串节点，root--根节点，param--参数节点，catchAll：通配符节点，例如*anyway</li>
<li>indices：子节点索引，当子节点为非参数类型，即本节点的wildChild为false时，会将每个子节点的首字母放在该索引数组</li>
</ul>
<p>&nbsp;</p>
<p>下面是第二个路由：GET /marketplace_listing/plans/:id/accounts</p>
<p>是一个新的GET请求，所以会新创建一个字典树：</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326153702688-1209261752.png" alt="" width="632" height="393" loading="lazy" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>当我们插入第三个路由：GET /search</p>
<p>因为之前存在一颗GET字典树了，而根节点是/market...，这和我们的新的路由丝毫无关，所以要抽离出一个新的根节点，使用二者重叠的前缀即可，目前只有 /&nbsp;</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326154914528-61697809.png" alt="" width="744" height="522" loading="lazy" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>同样地，我们继续插入后面两个路由：GET /status 和 GET /support，可以观察一下字典树的插入过程</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326155034611-692260153.png" alt="" width="829" height="481" loading="lazy" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h2>2.2 探究路由冲突问题</h2>
<p>当路由本身全都是字符串时，不会产生冲突，只有当出现了wildcard才可能会有冲突</p>
<p>让我们探究一下是什么造成了之前说的同一个http方法下的路由冲突问题：</p>
<ul>
<li>当插入wildcard节点时，父节点的children数组非空并且wildChild=false，那么自然这个wildcard节点就会产生冲突</li>
<li>当插入wildcard节点时，父节点的children数组非空且wildChild=true，但是该父节点的wildcard子节点要插入的wildcard名字不一样：GET /user/:id/info GET /user/:name/info</li>
<li>在插入catchAll节点时，父节点的children数组非空</li>
<li>在插入static节点时，父节点的wildChild=true</li>
<li>在插入static节点时，父节点的children非空，且子节点的nType=catchAll</li>
</ul>
<p>&nbsp;</p>