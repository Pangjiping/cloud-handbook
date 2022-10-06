<h1>1. 常用指令</h1>
<h2>1.1 创建一个java测试项目</h2>
<pre class="language-bash"><code>kubectl create deployment java-web --image=lizhenliang/java-demo</code></pre>
<p>&nbsp;</p>
<p>apply和create的区别：</p>
<p>apply是资源的创建和更新，create只能用于资源创建，再更新yaml之后是不能用create的</p>
<p>所以直接用apply代替create就可以</p>
<p>&nbsp;</p>
<h2>1.2 暴露端口</h2>
<p>这里暴露的端口是k8s内部访问的端口，外部访问端口需要在pod信息查看</p>
<p>实际上是创建了一个service资源</p>
<pre class="language-bash"><code>kubectl expose deployment java-web --port=80 --target-port=8080 --name=java-web-service --type=NodePort</code></pre>
<p>&nbsp;</p>
<p>查看暴露的端口信息，可以看到之前部署的那个java应用对外暴露在30850端口</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406153919048-2096366293.png" alt="" width="767" height="94" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>1.3 模拟升级</h2>
<p>如果应用上线之后需要升级，可以通过修改yaml的镜像源或者采用命令行的形式来修改</p>
<p>比如我们要把之前的java-web资源中的景象由java-demo更换为tomcat</p>
<pre class="language-bash"><code>kubectl set image deployment java-web java-demo=tomcat</code></pre>
<p>&nbsp;</p>
<p>查看pod的运行状况，可以看到在一个升级操作中，在新版本上线之前，旧版本不会停止运行</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406154308915-545193417.png" alt="" width="883" height="112" loading="lazy" /></p>
<p>&nbsp;</p>
<p>查看一个资源的历史版本信息</p>
<pre class="language-bash"><code>kubectl rollout history deployment/java-web</code></pre>
<p>&nbsp;</p>
<p>可以看到当前有两个版本</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406154501578-1294842007.png" alt="" width="714" height="110" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>1.4 回滚</h2>
<p>&nbsp;回滚到上一个版本</p>
<pre class="language-bash"><code>kubectl rollout undo deployment/java-web</code></pre>
<p>&nbsp;</p>
<p>回滚到指定版本</p>
<pre class="language-bash"><code>kubectl rollout undo deployment/java-web --to-revision=3</code></pre>
<p>&nbsp;</p>
<p>注意只能回滚到history能看到的历史版本，再往前是没办法回滚的</p>
<p>&nbsp;</p>
<h2>1.5 扩容</h2>
<pre class="language-bash"><code>kubectl scale deployment java-web --replicas=10</code></pre>
<p>&nbsp;</p>
<h2>1.6 删除</h2>
<p>删除资源不能直接删除pod，要删除其控制器，同时也要删除其service</p>
<pre class="language-bash"><code>kubectl delete deployment/java-web
kubectl delete service/java-web-service</code></pre>
<p>&nbsp;</p>
<h2>1.7 指令文档</h2>
<p><a href="http://docs.kubernetes.org.cn/683.html">Kubernetes kubectl 命令表 _ Kubernetes(K8S)中文文档_Kubernetes中文社区</a></p>
<p>&nbsp;</p>
<h1>2. YAML文件</h1>
<h2>2.1 YAML文件格式</h2>
<p>YAML是一种简洁的非标记语言</p>
<p>语法格式：</p>
<ul>
<li>缩进表示层级关系</li>
<li>不支持制表符 "tab" 缩进，使用空格缩进</li>
<li>通常开头缩进2个空格</li>
<li>字符后缩进1个空格，比如冒号、逗号</li>
<li>&ldquo;---&rdquo; 表示YAML格式，一个文件的开始</li>
<li>"#" 表示注释</li>
</ul>
<p>&nbsp;</p>
<h2>2.2 一个简单的YAML文件</h2>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406161411365-1316838100.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>整个YAML文件大体上可以分为定义控制器和定义被控制对象</p>
<p>在控制器部分：</p>
<ul>
<li>apiVersion：当前版本</li>
<li>kind：控制器类型，其中deployment就是用来部署无状态应用的</li>
<li>metadata：一些控制器的元信息，比如它之下的控制器名称name和控制器所在的命名空间namespace</li>
<li>spec：控制器的资源规格，控制3个副本数、标签选择器选择app:nginx这一组pod</li>
<li>template：pod的模板，其中包含了一些信息
<ul>
<li>metadata：pod的元信息，其中包含了一个标签信息app:nginx，表示这组pod受上面定义的deployment管理</li>
<li>spec：Pod的资源规格，包含了容器配置
<ul>
<li>containers：容器配置，主要包含容器名称、镜像源、暴露端口、数据卷挂载等</li>
</ul>
</li>
</ul>
</li>
</ul>
<p>&nbsp;</p>
<p>YAML文件关键字太多，格式太乱了记不住</p>
<p>可以使用以下两个命令导出YAML文件</p>
<pre class="language-bash"><code>kubectl create  deployment nginx --image=nginx:1.14 -o yaml --dry-run=client &gt; my-deploy.yaml</code></pre>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406163423918-1082632999.png" alt="" width="646" height="495" loading="lazy" /></p>
<p>&nbsp;</p>
<p>对于一个正在运行的pod，也可以通过get命名导出</p>
<p>这是一个比较全的YAML模板</p>
<pre class="language-bash"><code>kubectl get deploy nginx -o yaml &gt; nginx-deploy.yaml</code></pre>
<p>&nbsp;</p>
<p>可以用kebuctl explain来查看关键字的写法，以及其下级有什么字段</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406164120189-615006249.png" alt="" width="802" height="372" loading="lazy" /></p>
<p>&nbsp;</p>
<p>参考：</p>
<p><a href="https://www.kubernetes.org.cn/doc-45">Kubernetes（k8s）中文文档 kubectl_Kubernetes中文社区</a></p>
<p><a href="https://zhuanlan.zhihu.com/p/364994610">Kubernetes 之 kubectl 使用指南 - 知乎 (zhihu.com)</a></p>
<p><a href="http://docs.kubernetes.org.cn/683.html">Kubernetes kubectl 命令表 _ Kubernetes(K8S)中文文档_Kubernetes中文社区</a></p>
<p><a href="https://jimmysong.io/kubernetes-handbook/guide/using-kubectl.html">kubectl 命令概览 &middot; Kubernetes 中文指南&mdash;&mdash;云原生应用架构实战手册 (jimmysong.io)</a></p>