# **kubernetes**

- https://www.cnblogs.com/aganippe/p/16103657.html
- https://www.cnblogs.com/aganippe/p/16105278.html
- https://www.cnblogs.com/aganippe/p/16107277.html
- https://www.cnblogs.com/aganippe/p/16107332.html
- https://www.cnblogs.com/aganippe/p/16110900.html
- https://www.cnblogs.com/aganippe/p/16107342.html
- https://www.cnblogs.com/aganippe/p/16117757.html
- https://www.cnblogs.com/aganippe/p/16114663.html
- **https://www.huweihuang.com/kubernetes-notes/**
- **http://dockone.io/article/2434304**

## **基础问题**
---

### **基本架构**
---

![img](https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405193520557-115101348.png)

**master**
* API server - 集群统一入口，restful方式，交给etcd存储
* scheduler - 节点调度，选择node进行应用部署
* controller manager - 处理集群中常规后台任务，一个资源对应一个控制器
* etcd - 存储系统，用于保存集群中相关数据

**worker**
* kubelet - master派到node的代表，管理本机容器，并使node与master通信
* kube-proxy - Service的透明代理兼负载均衡器，其核心功能是将到某个Service的访问请求转发到后端的多个Pod实例上

<br>

### **kubernetes对象**
---
kubernetes中的对象就是一些持久化的实体，可以理解为是 `对集群状态的期望或描述`。kubernetes对象包括了:
* 集群中哪些node上运行了哪些容器化应用
* 应用的资源是否满足使用
* 应用的执行策略，例如重启策略、更新策略、容错策略等

**kubernetes对象是一种意图（期望）的记录，kubernetes会始终保持预期创建的对象存在和集群运行在预期的状态下**

**Spec和Status**

每个kubernetes对象的结构描述都包含了`spec`和`status`两个部分。
* spec: 该内容由用户提供，描述用户期望的对象特征及集群状态
* status: 给内容由kubernetes集群提供和更新，描述kubernetes对象的实时状态

在任何时候，kubernetes都会控制集群的实时状态status与spec保持一致。

推荐阅读: https://www.huweihuang.com/kubernetes-notes/concepts/object/understanding-kubernetes-objects.html

<br>

### **Pod**
---
**特点**
* 最小部署单元
* 一组容器的集合
* 共享网络和存储
* 生命周期短暂
	
**存在意义**
* pod是多进程设计，可以运行多个容器
* pod存在为了亲密性应用
	
**共享网络和存储**
* 共享网络
    - 前提：Pod在同一个namespace下
	- 通过node自动创建的Pause容器来共享网络
* 共享存储
	- Volume数据卷的方式
	
**健康检查**
* 存活检查：livenessProb
	- 如果检查失败，将容器杀死，根据pod的restartPolicy进行后续操作
	- restartPolicy
		- Always - 默认策略，当容器退出后总是重启
		- onFailure - 只有异常退出时才重启
		- Never - 永不重启
* 就绪检查：readinessProb
	- 如果检查失败，k8s会将pod从service endpoints中删除
	- Prob支持的检查方法
		- httpGet - 发送http请求，返回状态码200-400成功
		- exec - 执行shell命令，返回状态码0成功
		- tcpSocket - 发起tcp socket建立成功

**pod调度**
* pod资源限制
	- request和limit，既要满足request又不要超出limit
* 节点选择器标签
	- 首先node节点会被打上标签，在选择pod安装到哪个node时，根据标签选择
	- 类似于分组的概念，比如这个pod必须部署到测试组中去
* 节点亲和性
	- 硬亲和性 - 类似于nodeSelector，我必须被调度到哪一组node上
	- 软亲和性 - 尝试满足，不保证
* 污点和污点容忍
	- 这是对node做处理的
	- node不做普通调度，是node的一个属性
	- 使用场景
		- 专用节点
		- 配置特殊硬件的节点
		- 基于污点做驱逐操作
	- 三个污点值
		- NoSchedule - 一定不会被调度
		- PreferNoSchedule - 尽量不被调度
		- NoExecute - 不被调度，并且驱逐该node上所有的pod

**Pod创建流程**
* 客户端提交Pod的配置信息到apiserver
* apiserver收到指令后，通知给controller-manager创建一个资源对象
* controller-manager通过api-server将pod的配置信息存储到ETCD数据中心中
* Kube-scheduler调度node，将pod配置信息发送到kubelet
* Kubelet根据scheduler发来的资源配置单运行pod，并将运行信息返回给scheduler，scheduler发送给etcd
  
![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1631779724/article/kubernetes/pod/what-happens-when-k8s.svg)

<br>

### **Controller**
---

在集群上运行和管理容器的对象

**特点**
* 确保预期的pod副本数量
	- Replication Controller用来管理Pod的副本，保证集群中存在指定数量的Pod副本
* 无状态应用部署
	- kind: deployment
	- 认为所有pod都是一样的
	- 随意伸缩扩容
	- 不考虑在哪个node运行
	- 例子：web应用，微服务
* 有状态应用部署
	- kind: SatefulSet
	- 唯一网络标识，持久化存储
	- 有顺序创建
	- 例子：mysql主从
* 使所有node部署同一个pod
	- kind: Daemon
	- 部署守护进程
	- 例子：数据采集工具
* 一次性任务
	- kind: Job
* 定时任务
	- kind: CronJob

<br>

### **Service**
---

* 定义一组pod的访问策略（负载均衡）
* 防止pod失联（服务发现）
* 常用service类型
	- ClusterIP：虚拟的服务IP地址，该地址用于kubernetes集群内部的Pod访问，在Node上kube-proxy通过设置的iptables规则进行转发
	- NodePort：使用宿主机的端口，使能够访问各Node的外部客户端通过Node的IP地址和端口号就可以访问服务
	- LoadBalancer：使用外部负载均衡器完成到服务的负载分发，需要在spec.status.loadBalancer字段指定外部负载均衡器的IP地址，通常用于公有云

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510578930/article/kubernetes/concept/service.png)

<br>

### **Kubernetes Service分发后端的策略**
---

Service负载分发的策略有：RoundRobin和SessionAffinity
* RoundRobin: 默认为轮询模式，即将请求轮询转发到后端Pod上
* SessionAffinity: 基于客户端IP地进行会话保持的模式，即第一次将某个客户的请求转发到后端的某个Pod上，之后从相同的客户端发起的请求都将被转发到相同的Pod上

<br>

### **Kubernetes kubelet的作用**
---

在Kubernetes集群中，在每个Node（又称Worker）上都会启动一个kubelet服务进程。该进程用于处理Master下发到本节点的任务，管理Pod及Pod中的容器。每个kubelet进程都会在API Server上注册节点自身的信息，定期向Master汇报节点资源的使用情况，并通过cAdvisor监控容器和节点资源

<br>

### **Secret**
---

* 创建加密数据存储到etcd，让pod进行访问
* 两种挂载方式
	- 变量
	- volume
* 比如存储用户凭证

<br>

### **ConfigMap**
---

* 创建不加密数据存储到ectd，让pod访问
* 两种挂载方式
	- 变量
	- volume
* 比如存储配置信息

<br>

### **安全机制**
---

* 三步：认证，鉴权，准入控制
* 认证
	- https证书认证，基于ca证书
	- http token认证
	- http基本认证，用户名+密码
* 鉴权
	- 基于RBAC进行鉴权
		- 角色访问控制
		- 将主体绑定到角色上，各个角色对集群有不同的访问权限
* 准入控制
	- 就是准入控制器的列表，有请求内容就通过，没有就拒绝

<br>

### **Ingress**
---

* 解决NodePort的缺陷
	- NodePort只能通过ip+port来访问
	- NodePort会将所有的node都绑定到一个暴露端口号上，这意味着一个端口号只能使用一次
* ingress可以通过域名来访问

<br>

### **Helm**
---

**干什么？**
* 使用helm对yaml做统一管理
* 实现对yaml的复用
* 对应用版本管理

**Chart**
* 可以上传到Docker Hub
* 一个yaml文件包
* 实现多个yaml文件的安装和复用
	- 在template文件夹编写yaml
	- 在Value.yaml文件添加变量值
	- template中对应的yaml文件会读取这些变量，生成不同的Chart，实现对yaml文件格式的复用
	- {{.Value.变量名}} 类似于html模板

<br>

### **存储**
---

* nfs
	- 启用其他服务器做nfs服务器，对node部署nfs完成数据同步
	- 数据同步使用volume挂载文件夹
* pvc和pv
	- pv是外部存储系统中的一块存储空间，由管理员创建和维护。与 Volume 一样，PV 具有持久性，生命周期独立于 Pod
	- pvc是对pv的申请，用户只需要告诉 k8s 需要什么样的存储资源，而不必关心真正的空间从哪里分配，如何访问等底层细节信息

<br>

### **Prometheus**
---
https://www.cnblogs.com/aganippe/p/16286332.html

<br>

### **Pod调度流程**
---

https://www.huweihuang.com/kubernetes-notes/concepts/pod/pod-scheduler.html

<br>

## **细节问题**

### **informer机制**
---

在kubernetes系统中，组件之间通过http协议进行通信，通过informer来做到消息的实时性、可靠性、顺序性，通过informer机制与apiserver进行通信。

![img](https://pic4.zhimg.com/80/v2-b7ba279dad75649b02f3cfe6d81d8fcf_1440w.jpg)

**reflector**

informer可以对kubernetes apiserver的资源执行watch操作，类型可以是kubernetes内置资源也可以是crd自定义资源，其中最核心的功能是reflector。reflector用于监控指定资源的kubernetes资源，当资源发生变化的时候，例如发生了Added资源添加等事件会将其资源对象放在本地缓存DeltaFIFO中。

![img](https://pic2.zhimg.com/80/v2-dd8a368a019d7b69e08bc20f5b1d6599_1440w.jpg)

通过给`NewReflector`传入一个`listwatcher`数据接口对象来实例化一个reflector对象。reflector具备list和watch方法，最重要的是ListAndWatch。List用来获取资源列表数据，Watch用来监控资源对象，发生Event的时候插入本地缓存DeltaFIFO中并更新ResourceVersion。

**DeltaFIFO**

DeltaFIFO可以拆分开来理解。FIFO就是一个先入先出的队列，Delta是一个资源对象存储，它可以保存资源对象的操作类型

```go
// path: staging/src/k8s.io/client-go/tools/cache/delta_fifo.go
type DeltaFIFO struct {
...
    items map[string]Deltas
    queue []string
...
}
```

DeltaFIFO 的特点在于，入队列的是（资源的）事件，而出队列时是拿到的是最早入队列的资源的所有事件。这样的设计保证了不会因为有某个资源疯狂的制造事件，导致其他资源没有机会被处理而产生饥饿

![img](https://pic1.zhimg.com/80/v2-b421c75972cccba892ac510eb3a2dc58_1440w.jpg)

**Indexer**

indexer 是 client-go 用来存储资源对象并自带索引功能的本地存储，Reflector 从 DeltaFIFO 中江晓飞出来的资源对象存储至 indexer，indexer 要与 etcd 中的数据保持一致，这样无须每次都走 etcd 交互式拿到数据，能减轻 api-server 的压力

![img](https://pic1.zhimg.com/v2-4e7d219b2469769a27bb1433b636d4ac_r.jpg)

**informer工作流程**

* controller manager 在启动的时候会启动一个 sharedInformerFactory 这是一个 informer 的集合（informers map [reflect.Type] cache.SharedIndexInformer）。
* controller 在 run 的时候会调用 reflector 的 run，reflector 在 run 的时候会 listen and watch，当有 event 的时候插入本地缓存 DeltaFIFO 中并更新 ResouVersion。
* controller manager 会 watch and listen api-server 的 event，当有事件产生的时候，会通过 reflector 插入 deltafifo，
* DeltaFIFO 是一个先进先出的队列 ，通过生产者 （add 等等） 消费者（pop） 之后通过 sharedProcessor.distribute 分发给所有 listener 然后通过不同 controller 注册的 handler 来做逻辑处理。
* 最后 indexer 去做操作调用 treadsafestore 也就是底层存储的操作逻辑

推荐阅读：https://zhuanlan.zhihu.com/p/212579372

<br>

### **etcd**
---
**ETCD架构**

etcd主要分为四部分:
* HTTP Server: 用户处理用户发送的API请求以及其他etcd节点的同步与心跳信息请求
* Store: 用于处理etcd支持的各类功能的事务，包括数据索引、节点状态变更、监控与反馈、事件处理和执行等，是etcd对用户提供的大多数API功能的具体实现
* Raft: Raft一致性算法的具体实现，是etcd的核心
* WAL: Write Ahead Log(预写日志)，是etcd的数据存储方式。除了在内存中有所有数据的状态以及节点的索引信息外，etcd通过WAL进行持久化存储。WAL中，所有的数据提交前都会事先记录日志。Snapshot是为了防止数据过多而进行的状态快照；Entry表示存储的具体日志内容。

![img](http://www.zhaowenyu.com/etcd-doc/assets/img/etcd-arch2.jpg)

通常，一个用户的请求发送过来，会经由HTTP Server转发给Store进行具体的事务处理，如果涉及到节点的修改，则交给Raft模块进行状态变更、日志记录，然后再痛不给别的etcd节点确认数据提交，最后进行数据提交，再次同步。

**etcd如何保证一致性**

etcd使用raft算法保证一致性，而raft算法主要包括两个部分:leader选举和日志复制

数据在etcd中只有一个流向，那就是从leader -> follower

**主从数据同步**
* client连接follower或者leader，如果连接到的是follower则follower会把client的写请求转发给leader
* leader收到client的请求，将请求转化为entry，写入到自己的日志中，得到在日志中的index，然后将该entry发送给所有的follower（实际上是批处理）
* follower接收到leader的AppendEntriesRPC之后，会讲leader传来的批量entries写入到文件中（通常没有立刻写盘），然后向leader回复OK，leader收到过半的OK之后，就认为可以提交了，然后应用到leader自己的状态机中，leader更新commitIndex，应用完毕后回复客户端
* 在下一次的leader发送给follower的心跳中，会将leader的CommitIndex传递给follower，follower发现CommitIndex更新了则也会讲CommitIndex之前的日志都进行提交和应用到状态机中

**leader选举**
* 当集群初始化时候，每个节点都是Follower角色；都维护一个随机的timer，如果timer时间到了还没有收到leader的消息，自己就会变成candidate，竞选leader
* 当Follower在一定时间内没有收到来自主节点的心跳，会将自己角色改变为Candidate，并发起一次选主投票；当收到包括自己在内超过半数节点赞成后，选举成功；当收到票数不足半数选举失败，或者选举超时。若本轮未选出主节点，将进行下一轮选举（出现这种情况，是由于多个节点同时选举，所有节点均为获得过半选票）
* 集群中存在至多1个有效的主节点，通过心跳与其他节点同步数据
* Candidate节点收到来自主节点的信息后，会立即终止选举过程，进入Follower角色。为了避免陷入选主失败循环，每个节点未收到心跳发起选举的时间是一定范围内的随机值，这样能够避免2个节点同时发起选主




推荐阅读: https://hardcore.feishu.cn/docs/doccnMRVFcMWn1zsEYBrbsDf8De

<br>

### **Replication Controller**
---

RC是kubernetes的核心概念，定义了一个期望的场景。主要包括:
* Pod的期望副本数量 - replicas
* 用于筛选目标Pod的LabelSelector
* 用于创建Pod的模版 - template

RC特性说明:
* Pod的缩放可以通过以下命令实现：
```bash
$ kubectl scale rc redis-slave --replicas=3
```
* 删除RC并不会删除该RC创建的Pod，可以将副本数量设置为0，即可删除对应的Pod
* 改变RC中Pod模版的镜像可以实现滚动升级
* Kubernetes1.2以上版本将RC升级为Replica Set，它与当前RC的唯一区别在于Replica Set支持基于集合的Label Selector(Set-based selector)，而旧版本RC只支持基于等式的Label Selector(equality-based selector)
* Kubernetes1.2以上版本通过Deployment来维护Replica Set而不是单独使用Replica Set。即控制流为：Delpoyment→Replica Set→Pod。即新版本的Deployment+Replica Set替代了RC的作用

<br>

### **RC与HPA**
---

Horizontal Pod Autoscaler(HPA)即Pod横向自动扩容，与RC一样也属于k8s的资源对象

HPA原理：通过追踪分析RC控制的所有目标Pod的负载变化情况，来确定是否针对性调整Pod的副本数。

Pod负载度量指标：

* CPUUtilizationPercentage：Pod所有副本自身的CPU利用率的平均值。即当前Pod的CPU使用量除以Pod Request的值。
* 应用自定义的度量指标，比如服务每秒内响应的请求数（TPS/QPS）。

**Pod伸缩**

kubernetes中的RC用来保持集群中始终运行指定数目的实例，通过RC的scale机制可以完成Pod的扩容

* 手动伸缩 scale
```bash
$ kubectl scale rc redis-slave --replicas=3
```

* 自动伸缩

Horizontal Pod Autoscaler(HPA)控制器用于实现基于CPU使用率进行自动Pod伸缩的功能。HPA控制器基于Master的KCM服务启动参数 `--horizontal-pod-autoscaler-sync-period`定义时长，周期性监控目标Pod的CPU使用率。并在满足条件时对ReplicationController或Deployment中的Pod副本数进行调整，以符合用户定义的平均Pod CPU使用率。

```yaml
apiVersion: v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: v1
    kind: ReplicationController
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```

**Pod的滚动升级**

k8s中的滚动升级通过执行kubectl rolling-update命令完成，该命令创建一个新的RC（与旧的RC在同一个命名空间中），然后自动控制旧的RC中的Pod副本数逐渐减少为0，同时新的RC中的Pod副本数从0逐渐增加到附加值，但滚动升级中Pod副本数（包括新Pod和旧Pod）保持原预期值

* 新的RC的不能与旧的RC名字相同
* 在selector中至少有一个label与旧的RC的label不同，以标识其为新的RC。可以用version作为区分

推荐阅读: https://www.huweihuang.com/kubernetes-notes/concepts/pod/pod-operation.html

<br>

### **Kube Controller Manager**
---

KCM作为集群内部的管理控制中心，负责集群内的Node、Pod副本、服务端点、命名空间、服务账号、资源定额的管理

![img](http://res.cloudinary.com/dqxtn0ick/image/upload/v1510579017/article/kubernetes/core/controller-manager.png)

每个Controller通过API Server提供的接口实时监控整个集群的每个资源对象的当前状态，当发生各种故障导致系统状态发生变化时，会尝试将系统状态修复到“期望状态”。

**Replication Controller**

**Node Controller**

kubelet在启动时会通过API Server注册自身的节点信息，并定时向API Server汇报状态信息，API Server接收到信息后将信息更新到etcd中。

Node Controller通过API Server实时获取Node的相关信息，实现管理和监控集群中的各个Node节点的相关控制功能。流程如下

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510579017/article/kubernetes/core/NodeController.png)

**ResourceQuota Controller**

资源配额管理确保指定的资源对象在任何时候都不会超量占用物理资源。

支持三个层次的资源配置管理：
* 容器级别：对CPU和Mem进行限制
* Pod级别：对一个Pod内所有容器的可用资源进行限制
* Namespace级别：包括
	* Pod数量
	* Replication Controller数量
	* Service数量
	* ResourceQuota数量
	* Secret数量
	* 可持有的PV的数量

说明：
* kubernetes配额管理是通过Admission Control来控制的
* Admission Control提供两种配额约束的方式：LimitRanger和ResourceQuota
* LimitRanger做作用于Pod和Container
* ResourceQuota作用于namespace，限定一个namespace里面各类资源的使用总额

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510579017/article/kubernetes/core/ResourceQuotaController.png)

**Namespace Controller**

用户通过API Server可以创建新的Namespace并保存在etcd中，Namespace Controller定时通过API Server读取这些Namespace信息。

如果Namespace被API标记为优雅删除（即设置删除期限，DeletionTimestamp）,则将该Namespace状态设置为“Terminating”,并保存到etcd中。同时Namespace Controller删除该Namespace下的ServiceAccount、RC、Pod等资源对象。

**Endpoints Controller**

Endpoints表示了一个Service对应的所有Pod副本的访问地址，而Endpoints Controller负责生成和维护所有Endpoints对象的控制器。它负责监听Service和对应的Pod副本的变化。

* 如果检测到Service被删除，则删除和该Service同名的Endpoints对象
* 如果检测到新的Service被创建或者修改，则根据该Service信息获得相关Pod列表，然后创建或更新Service对应的Endpoints对象
* 如果检测到Pod的事件，则更新它对应的Service的Endpoints对象

kube-proxy进程获取每个Service的Endpoint，实现Service的负载均衡功能。

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510579017/article/kubernetes/core/EndpointController.png)

**Service Controller**

Service Controller是属于kubernetes集群与外部的云平台之间的一个接口控制器。Service Controller监听Service变化，如果是一个LoadBalancer类型的Service，则确保外部的云平台上对该Service对应的LoadBalancer实例被相应地创建、删除及更新路由转发表。

<br>

### **Scheduler**
---
Scheduler负责Pod调度。在整个系统中起"承上启下"作用，承上：负责接收Controller Manager创建的新的Pod，为其选择一个合适的Node；启下：Node上的kubelet接管Pod的生命周期

* 通过调度算法为待调度的Pod列表的每个Pod从Node列表中选择一个合适的Node，并将信息写入ETCD
* kubelet通过api server监听到kubernetes scheduler产生的Pod绑定信息，然后获取对应的Pod清单，下载image并启动容器

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510579017/article/kubernetes/core/scheduler.png)

**调度流程**

* 预选策略
  * NoDiskConfilct: 数据挂载点冲突
  * PodFitsResources: 资源是否满足
  * PodSelectorMatches: label筛选
  * PodFitsHost: spec.nodeName字段
  * CheckNodeLabelPresence: 检查节点是否有scheduler配置的标签
  * CheckServiceAffinity:
  * PodFitsPorts: Pod所用的端口列表中的端口是否在备选节点中已被占用
* 优选策略
  * LeastRequestedPriority: 优先从备选节点列表中选择资源消耗最小的节点（CPU+内存）
  * CalculateNodeLabelPriority: 优先选择有指定Label的节点
  * BalancedResourceAllocation: 优先从备选节点列表中选择各项资源使用率最均衡的节点

<br>

### **kubernetes网络模型**
---

* 在kubernetes网络模型中，每个Pod都拥有一个独立的IP地址。并假定所有的Pod都在一个可以直接连通的、扁平化的网络空间中。所以不管它们是否运行在同一个Worker上，都要求它们可以直接通过对方的IP进行访问。此设计的原因是，用户不需要额外考虑如何建立Pod之间的连接，也不需要考虑如何将容器端口映射到主机端口等问题
* 每个Pod都设置一个IP地址的模型使得同一个Pod的不同容器可以共享同一个网络命名空间，也就是同一个Linux网络协议栈。这就意味着同一个Pod内的容器可以通过localhost来连接对方的端口
* 在kubernetes集群中，IP是以Pod为单位进行分配的。一个Pod内不得所有容器共享一个网络堆栈。

推荐阅读: https://www.huweihuang.com/kubernetes-notes/network/kubernetes-network.html

<br>

### **kube-proxy**
---
kube-proxy运行在所有节点上，它监听apiserver中service和endpoint的变化，创建路由规则以提供服务IP和负载均衡的功能。简单理解就是此进程是service的透明代理兼负载均衡器，其核心功能是将到某个service的访问请求转发到后端的多个Pod上。

<br>

### **iptables和ipvs**
---
iptables模式下的kube-proxy不再起到Proxy的作用，其核心功能：通过API Server的Watch接口实时跟踪Service与Endpoint的变更信息，并更新对应的iptables规则，Client的请求流量则通过iptables的NAT机制“直接路由”到目标Pod

IPVS则专门用于高性能负载均衡，并使用更高效的数据结构（Hash表），允许几乎无限的规模扩张，因此被kube-proxy采纳为最新模式。在IPVS模式下，使用iptables的扩展ipset，而不是直接调用iptables来生成规则链。iptables规则链是一个线性的数据结构，ipset则引入了带索引的数据结构，因此当规则很多时，也可以很高效地查找和匹配。可以将ipset简单理解为一个IP（段）的集合，这个集合的内容可以是IP地址、IP网段、端口等，iptables可以直接添加规则对这个“可变的集合”进行操作，这样做的好处在于可以大大减少iptables规则的数量，从而减少性能损耗。

**ipvs和iptables的异同**

iptables是为防火墙设计的，ipvs则专门用于高性能的负载均衡，并使用更高效的数据结构（Hash表）

与iptables相比，ipvs拥有以下明显优势:
* 为大型集群提供了更好的可扩展性和性能
* 支持比iptables更复杂的负载均衡算法（最小负载、最少连接、加权等）
* 支持服务器健康检查和连接重试等功能
* 可以动态修改ipset的集合，即使iptables的规则正在使用这个集合

<br>

### **Static Pod**
---

静态pod在指定的节点上由kubelet守护进程直接管理，而不需要通过apiserver监管。kubelet监视每个pod在崩溃之后重启。静态Pod永远都会绑定到一个指定节点上的 Kubelet。

kubelet 会尝试通过 Kubernetes API 服务器为每个静态 Pod 自动创建一个 镜像 Pod。 这意味着节点上运行的静态 Pod 对 API 服务来说是可见的，但是不能通过 API 服务器来控制。 Pod 名称将把以连字符开头的节点主机名作为后缀。

kubelet定期扫描此目录 /etc/kubernetes/manifests，来判断pod是否需要增加和删除

![img](https://upload-images.jianshu.io/upload_images/25438319-441be27b46acd42a.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200)

最常见的静态pod：
* etcd
* kube-apiserver
* kcm
* kube-scheduler

推荐阅读: https://www.jianshu.com/p/ca8f85767caf

<br>

### **kubernetes ingress**
---
kubernets的ingress资源对象，用于将不同的URL的访问请求转发到后端不同的Service，以实现HTTP层的业务员路由机制

Kubernetes使用了ingress策略和ingress controller，二者结合并实现了一个完整的ingress负载均衡器。使用ingress进行负载分发时，ingress controller基于ingress规则将ingress规则将客户端请求直接转发到Service对应的后端Pod上，从而跳过kube-proxy的转发功能，kube-proxy不再起作用，全过程如下:

ingress controller + ingress规则 -> services

同时当ingress controller提供的是对外服务，则实际上实现的是边缘路由器的功能

<br>

### **kubernetes负载均衡**
---

负载均衡器是暴露服务的最常见和标准方式之一

根据工作环境使用两种类型的负载均衡器，即内部负载均衡器或外部负载均衡器。内部负载均衡器自动平衡负载并使用所需配置分配容器，而外部负载均衡器将流量从外部负载引导至后端容器。

<br>

### **Pod内部是如何实现资源共享的**
---
一个Pod内的容器可以共享网络和存储

我们知道容器的实现是基于容器运行时（如docker），容器之间是通过namespace隔离的，那么在Pod中想要实现资源共享，就需要用网络和文件系统来解决namespace隔离

在创建pod的时候会创建`infra container`这个容器，启动之后再将实际创建的pod加入到该容器中。这个容器的目的就是为了维护整个Pod的网络。其他容器的创建都让其连接至该容器的网络命名空间当中。这样一来其他容器看到的网络视图就是infra container的网络视图了。一个pod当中所有的容器看到的网络设备，网卡，ip，mac地址都看到的是同一个了，因为在一个网络命名空间。这样就解决了网络共享的问题。实际上pod的ip就是infra container的ip

pod通过volumn来实现共享存储

<br>