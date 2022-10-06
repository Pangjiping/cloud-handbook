<h1>1. service</h1>
<ul>
<li>防止pod失联（服务发现）</li>
<li>定义一组pod的访问规则（负载均衡）</li>
</ul>
<p>&nbsp;</p>
<p><strong>服务发现</strong></p>
<p>假设现在是一个deployment控制器，一般为了保证高可用都会至少部署三个副本，而且三个pod都有独立的ip地址</p>
<p>当一个pod挂掉之后，deployment会立刻拉取一个新的pod，但是新pod的ip地址明显是和挂掉的那个pod不一样</p>
<p>这时候service就发挥了作用，前端和后端pod不需要通过ip地址来直接通信，而是经由service来做一个统一的管理操作</p>
<p>&nbsp;</p>
<p><strong>负载均衡</strong></p>
<p>当我有多个副本时，客户端发送的请求需要具体转发到哪个pod上，这就是负载均衡</p>
<p>&nbsp;</p>
<h2>1.1 Pod和Service的关系</h2>
<ul>
<li>pod与service通过label-selector关联</li>
<li>通过service实现pod的负载均衡（<span style="color: #ff0000;">TCP/UDP四层，只负责IP数据包转发</span>）</li>
</ul>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407135617850-1509125163.png" alt="" loading="lazy" /></p>
<p>Service看起来就像是为Pod提供了一个网络代理的功能</p>
<p>&nbsp;</p>
<h2>1.2 Service常用类型</h2>
<ul>
<li>ClusterIP：默认设置，集群内部使用</li>
<li>NodePort：对外暴露应用</li>
<li>LoadBalancer：对外暴露应用，适用于公有云</li>
</ul>
<p>比如在一个客户端-后端-数据库的业务架构中，客户端-后端、后端-数据库之间的通信就要选择ClusterIP，因为这些都不需要暴露</p>
<p>而用户和客户端之间就需要使用NodePort，即我们要把客户端的服务暴露出去</p>
<p>&nbsp;</p>
<h3><strong>1.2.1 ClusterIP</strong></h3>
<p>分配一个稳定的IP地址，即VIP，只能在集群内部访问，<strong>同一个namesapce内的pod</strong></p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407141344754-681668939.png" alt="" loading="lazy" /></p>
<p>最典型的ClusterIP就是k8s集群服务的service，我们可以通过下面的指令查看所有的svc</p>
<pre class="language-bash"><code>kubectl get svc</code></pre>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407142026982-1064550061.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>这个虚拟IP可以在任意一个节点、任意一个pod内访问</p>
<p>&nbsp;</p>
<h3><strong>1.2.2 NodePort</strong></h3>
<p>提供一个端口，供外部访问，但其存在一个问题就是可以通过所有的&lt;NodeIP+port&gt;的形式来访问</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407143834701-75198941.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>对外暴露的端口号从30000起，默认是集群随机分配的</p>
<p>也可以通过spec.ports.nodePort字段来指定一个暴露端口，但注意可能会存在端口占用情况</p>
<p>这个暴露的端口在每个节点都会监听，不论这个节点有没有提供服务的pod</p>
<p>&nbsp;</p>
<p>外界访问任意一个node都可以获取服务，通过 &lt;NodeIP:NodePort&gt; 的形式，然后统一由service来做负载均衡</p>
<p>&nbsp;</p>
<p>比如在下面这个svc列表中，web是作为NodePort类型的，可以看到它在 PORT(S)这一项是有两个端口号</p>
<p>左侧是集群内部访问的，也就是一种ClusterIP</p>
<p>右边是通过节点IP地址暴露出去的一个端口号</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407142026982-1064550061.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>一般来讲，生产环境中所有的node都部署在内网，即使暴露了端口，在公网上也无法访问</p>
<p>这时候一般会有以下解决方案：</p>
<ul>
<li>找一台有公网IP的服务器，使用nginx反向代理到node</li>
<li>使用外部负载均衡器，比如nginx、LVS、HAProxy做负载均衡，将流量转发到node</li>
</ul>
<p>&nbsp;</p>
<h3><strong>1.2.3 LoadBalancer</strong></h3>
<p>与NodePort类似，在每个节点上启用一个端口来暴露服务</p>
<p>除此之外，k8s还会请求底层云平台上的负载均衡器，将每个Node &lt;NodeIP:NodePort&gt; 作为后端添加进去</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407144642253-2033509059.png" alt="" loading="lazy" /></p>
<p>用户通过访问公有云上的负载均衡器来访问node&nbsp;</p>
<p>&nbsp;</p>
<h2>1.3 Service代理模式</h2>
<h3>1.3.1 Iptables</h3>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407145614903-68703753.png" alt="" loading="lazy" /></p>
<p>iptables是Service的默认模式</p>
<p>iptables能做什么？</p>
<ul>
<li>阻断IP通信</li>
<li>端口映射NAT</li>
<li>跟踪包的状态</li>
<li>数据包的修改</li>
</ul>
<p>&nbsp;</p>
<p>kube-proxy组件默认实现iptables，具体来讲就是实现数据包在node之间的转发</p>
<p>将service相关规则来落地实现</p>
<p>如果使用NodePort的访问规则的话，我们在外部访问任意节点IP+暴露端口，采取轮询机制找到一个提供服务的pod</p>
<p>NodePort：192.167.11.89:30008</p>
<p>　　　　　-&gt; KUBE-SVC-XXXXXX （负载均衡） --probalility&nbsp; 0.3333333</p>
<p>　　　　　-&gt; KUBE-SEP-YYYYYYY</p>
<p>　　　　　-&gt; -j DNAT --to-destination 10.244.2.2:80 (提供服务的Pod)</p>
<p>&nbsp;</p>
<p>iptables的特点：</p>
<ul>
<li>灵活，功能强大</li>
<li>规则遍历匹配和更新，呈线性时延</li>
</ul>
<p>&nbsp;</p>
<h3>1.3.2 IPVS</h3>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407145628545-1146644621.png" alt="" loading="lazy" /></p>
<p>LVS就是基于ipvs模块实现的四层负载均衡器</p>
<p>ipvs特点：</p>
<ul>
<li>工作在内核态，有更好的性能</li>
<li>调度算法丰富：rr、wrr、lc、wlc、ip hash ...</li>
</ul>
<p>&nbsp;</p>
<h1>2. Ingress</h1>
<p>为什么需要Ingress？</p>
<p>首先来看一下NodePort存在的问题：</p>
<ul>
<li>一个端口只能一个服务来使用，因为在所有的Node上都暴露了这个端口</li>
<li>只支持四层的负载均衡</li>
</ul>
<p>&nbsp;</p>
<h2>2.1 Ingress和Pod的关系</h2>
<ul>
<li>通过Service完成关联</li>
<li>通过Ingress Controller实现Pod的负载均衡，支持TCP/UDP四层和HTTP七层</li>
</ul>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407153510523-1758664838.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>2.2 部署Ingress Controller</h2>
<p>Ingress Controller有很多实现，官方维护的是nginx控制器，其他的主流控制器也有Traefik和Istio</p>
<p>官方提供了很多第三方控制器的项目地址：<a href="https://kubernetes.io/zh/docs/concepts/services-networking/ingress-controllers/">Ingress 控制器 | Kubernetes</a></p>
<p>我们使用官方的nginx控制器，下载好yaml之后需要修改镜像源为国内镜像源，修改hostNetwork: true</p>
<pre class="language-bash"><code>wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml &gt; ic.yaml</code></pre>
<p>&nbsp;</p>
<p>根据这个YAML文件创建两个pod，其实是和节点数有关，这是以DaemonSet方式部署的</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407154710031-207626905.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>2.3 设置Ingress规则</h2>
<p>对于下面这个ingress规则，首先需要指定kind为ingress</p>
<p>最重要的就是service字段，指明暴露的服务名称和端口</p>
<p>同时通过域名绑定服务，如果测试的话需要修改本机hosts来访问</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407155326389-1214371705.png" alt="" loading="lazy" /></p>
<h2>2.4 Ingress根据URL路由到多个服务</h2>
<p>比如在下面的示例中，Ingress管理了两个service</p>
<p>用户可以通过域名的方式来访问这两个service，其中/foo和/bar就负责路由的转发</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407155619368-1470801868.png" alt="" loading="lazy" /></p>
<p>这个Ingress规则的YAML文件如下所示：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407155852037-974491412.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>Ingress规则中有两个后端service，路由路径分别为/foo和/bar</p>
<p>当我们访问foo.bar.com/foo时，ingress就会帮我路由到service1，访问foo.bar.com/bar时，ingress会路由到service2</p>
<p>其中的pathType: Prefix是前缀匹配，也就是说只要是以 "/foo" 开头的URL都会被路由到service1</p>
<p>匹配规则可见：<a href="https://kubernetes.io/zh/docs/concepts/services-networking/ingress/">Ingress | Kubernetes</a></p>
<p>&nbsp;</p>
<h2>2.5 Ingress Controller高可用方案</h2>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407163327569-1986542236.png" alt="" loading="lazy" /></p>
<p>其中集群模式更为常见，可以在公网节点上部署一个负载均衡器，比如nginx，把流量转发给Ingress Controller</p>
<p>&nbsp;</p>
<p>参考：</p>
<p><a href="https://kubernetes.io/zh/docs/concepts/services-networking/ingress/">Ingress | Kubernetes</a></p>
<p><a href="https://kubernetes.github.io/ingress-nginx/deploy/">Installation Guide - NGINX Ingress Controller (kubernetes.github.io)</a></p>
<p><a href="https://kubernetes.io/zh/docs/concepts/services-networking/ingress-controllers/">Ingress 控制器 | Kubernetes</a></p>
<p>&nbsp;</p>