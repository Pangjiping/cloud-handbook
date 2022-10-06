<h1>1. k8s架构组件</h1>
<p>kubernetes是一个用于自动部署、扩展和管理容器化应用程序的开源系统</p>
<p>&nbsp;</p>
<h2>1.1 k8s的基本架构</h2>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405193520557-115101348.png" alt="" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>和一些分布式存储和分布式数据库集群类似，在k8s集群中，也存在着master节点和node节点</p>
<p>其中master节点主要负责pod调度、服务注册、服务发现等一系列管理相关的工作</p>
<p>node节点主要是部署pod，提供服务</p>
<p>&nbsp;</p>
<p>在master节点中，有以下重要组件：</p>
<ul>
<li>kube-apiserver</li>
<li>kube-controller-manager</li>
<li>kub-scheduler</li>
<li>etcd</li>
</ul>
<p>在node节点中，有以下重要组件：</p>
<ul>
<li>kubelet</li>
<li>kube-proxy</li>
<li>docker/rocket</li>
</ul>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405200220301-24449329.png" alt="" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<h2>1.2 master节点组件功能介绍</h2>
<p>（1）kube-apiserver</p>
<p>　　kubernetes API，集群的统一入口，各组件的协调者，以RESTful API提供接口服务</p>
<p>　　所有对象资源的增删改查和监听操作都交给APIserver处理后提交给ETCD存储</p>
<p>（2）kube-controller-manager</p>
<p>　　处理集群中常规后台任务，一个资源对应一个控制器，而controller-manager就是管理这些控制器的</p>
<p>（3）kube-scheduler</p>
<p>　　根据调度苏算法为新创建的pod选择一个node节点部署</p>
<p>（4）etcd</p>
<p>　　一个golang开发的分布式key-value数据库，主要负责存储集群的状态数据、</p>
<p>　　etcd可以和多master组成一个etcd集群，也可以从master节点分离单独部署，只要保证APIserver可以访问etcd就可以</p>
<p>　　当然由于rpc的不可靠性，etcd大多数情况下是部署在master节点上</p>
<p>&nbsp;</p>
<h2>1.3 node节点组件功能介绍</h2>
<p>（1）kubelet</p>
<p>　　kubelet是master节点在node节点上的代理agent，管理本机容器的生命周期，比如创建容器、pod挂载数据卷、下载secret、获取容器和节点的状态等</p>
<p>　　kubelet将每个pod转换成一组容器进行部署</p>
<p>（2）kube-proxy</p>
<p>　　在node节点上实现pod网络代理，维护网络规划和四层负载均衡工作</p>
<p>（3）docker/rocket</p>
<p>　　底层容器引擎，运行和部署容器</p>
<p>&nbsp;</p>
<h1>2. k8s核心概念</h1>
<h2>2.1 Pod</h2>
<ul>
<li>最小的部署单元</li>
<li>多个容器的集合</li>
<li>pod内容器共享网络和数据</li>
<li>pod的生命周期短暂</li>
</ul>
<p>&nbsp;</p>
<h2>2.2 Controller</h2>
<ul>
<li>Deployment：部署无状态应用，比如一些web服务</li>
<li>StatefulSet：部署有状态应用，比如mysql集群</li>
<li>DaemonSet：守护进程，确保所有node都运行某个pod，比如一些监控和日志收集服务</li>
<li>Job：一次性任务</li>
<li>Cronjob：定时任务，比如定时清理持久化文件等</li>
</ul>
<p>&nbsp;</p>
<h2>2.3 Service</h2>
<ul>
<li>防止pod失联</li>
<li>定义一组pod的访问策略</li>
</ul>
<p>&nbsp;</p>
<h1>2. k8s学习资源</h1>
<p>最重要的学习资源就是k8s的官方文档：<a href="https://kubernetes.io/zh/docs/home/">Kubernetes 文档 | Kubernetes</a></p>
<p>官方文档提供了很多部署案例和一些概念的深入讲解</p>
<p>&nbsp;</p>
<p>阿里云的公开课：<a href="https://developer.aliyun.com/learning/roadmap/cloudnative2020">阿里巴巴云原生技术实践公开课-阿里云开发者社区 (aliyun.com)</a></p>
<p><a href="https://edu.aliyun.com/roadmap/cloudnative">CNCF x Alibaba 云原生技术公开课 - 云原生教程 - 阿里云全球培训中心 (aliyun.com)</a></p>
<p>&nbsp;</p>
<p>另外就是k8s的源码学习，详见github，同时可以参考张磊的深入剖析k8s、郑东旭的k8s源码剖析</p>