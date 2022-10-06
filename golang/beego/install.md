<h1>1. 第一个beego项目</h1>
<p>首先需要安装依赖，go 1.18版本使用 go install 命令</p>
<pre class="language-bash"><code>go get -u github.com/beego/beego/v2
go get -u github.com/beego/bee/v2</code></pre>
<p>&nbsp;</p>
<p>另外更新一个GOPROXY，快速响应go get或者go install，亲测非常好用</p>
<p>同样可以在goland中修改这个代理</p>
<pre class="language-bash"><code>go env -w GOPROXY=https://goproxy.cn
go env -w GO111MODULE="on"</code></pre>
<p>&nbsp;</p>
<p>使用bee命令行工具创建一个初始项目</p>
<pre class="language-bash"><code>bee new demo01</code></pre>
<p>&nbsp;</p>
<p>管理项目依赖</p>
<pre class="language-bash"><code>go mod tidy</code></pre>
<p>&nbsp;</p>
<p>运行demo，默认8080端口</p>
<pre class="language-bash"><code>bee run</code></pre>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220410132219564-1643839999.png" alt="" width="899" height="468" loading="lazy" /></p>
<h1>2. beego的项目结构</h1>
<p>beego的项目结构遵循MVC结构，即Model View Controller</p>
<p>我们可以通过tree简单查看一下通过bee new创建的一个项目结构</p>
<pre class="language-bash"><code>D:.
├─conf
├─controllers
├─models
├─routers
├─static
│  ├─css
│  ├─img
│  └─js
├─tests
└─views</code></pre>
<p>&nbsp;</p>
<ul>
<li>conf文件下存放配置信息</li>
<li>controllers目录下存放控制器代码</li>
<li>models目录下存放数据结构模型，包括数据库模型</li>
<li>routers目录下存放路由信息</li>
<li>static目录存放静态资源</li>
<li>views主要存放前端页面</li>
<li>tests存放测试文件和数据</li>
</ul>
<p>&nbsp;</p>
<h1>3. bee工具简介</h1>
<p>在终端输入 bee 可以看到bee工具的所有命令</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220410133506612-546008950.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>下面介绍几个比较常用的</p>
<h2>3.1 bee new 新建项目</h2>
<pre class="language-bash"><code>bee new project</code></pre>
<p>创建出的项目就是一个标准的MVC架构，我们可以在此基础上开发自己的业务代码</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220410133545523-1543903084.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>3.2 bee api 新建一个api项目</h2>
<pre class="language-bash"><code>bee api project02</code></pre>
<p>&nbsp;</p>
<p>创建一个api项目，前后端分离，更像我们自己写的api后端架构</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220410133836750-597944034.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>3.3 bee run 运行当前项目</h2>
<pre class="language-bash"><code>bee run</code></pre>
<p>和 go run main.go一样的</p>
<p>&nbsp;</p>
<h2>3.4 bee pack 打包项目</h2>
<pre class="language-bash"><code>bee pack</code></pre>
<p>&nbsp;</p>
<p>将编译通过的项目打包成一个.tar.gz压缩文件</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220410134109831-1488497062.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>