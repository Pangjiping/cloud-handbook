# **容器网络和kubernetes网络**

## **1. Docker的网络基础**

### **1.1 Network Namespace**

不同的网络命名空间中，协议栈是独立的，完全隔离，彼此之间无法通信。同一个网络命名空间有独立的路由表和独立的`IPtables/Netfilter`来提供包的转发、NAT、IP包过滤等功能。

**网络命名空间的实现**

将网络协议栈相关的全局变量变成一个`Net Namespace`变量的成员，然后在调用协议栈函数中加入一个Namespace参数。

**网络命名空间的操作**

* 创建网络命名空间: ip netns add `name`
* 在命名空间中执行命令: ip netns exec `name` `command`
* 进入命名空间: ip netns exec `name` bash

<br>

## **2. Docker的网络实现**

### **2.1 容器网络**

Docker使用Linux桥接，在宿主机虚拟一个Docker容器网桥(**docker0**)，Docker启动一个容器时会根据Docker网桥的网段分配给容器一个IP地址，称为`Container-IP`，同时Docker网桥是每个容器的默认网关。因为在同一个宿主机内的容器都接入同一个网桥，这样容器之间就能够通过容器的`Container-IP`直接通信。

Docker网桥是素主机虚拟出来的，并不是真实存在的网络设备，外部网络是无法寻址到的，这也意味着外部网络无法通过`Container-IP`访问到容器。如果容器希望外部访问能够访问到，可以通过映射容器端口到宿主机（端口映射），即`docker run`创建容器时通过`-p`或者`-P`参数来启动，访问容器的时候就可以通过`宿主机IP:容器端口`来访问容器。

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510578957/article/kubernetes/network/container-network.png)

<br>

### **2.2 四类网络模式**

| docker网络模式 | 配置 | 说明
| :---- | :---- | :---- |
| host模式 | `--net=host` | 容器和宿主机共享一个Network Namespace |
| container模式 | `--net=container:NAME_or_ID` | 容器和另外一个容器共享Network Namespace。kubernetes中的Pod就是多个容器共享一个Network Namespace |
| none模式 | `--net=none` | 容器有独立的Network Namespace，但并没有对其进行任何网络设置，如分配veth pair和网桥连接，配置IP等等 |
| bridge模式 | `--net=bridge` | 默认的桥接模式 |

<br>

## **3. Docker网络模式**

### **3.1 bridge桥接模式**

在bridge模式下，Docker可以使用独立的网络栈。实现方式是父进程在创建子进程的时候通过传入`CLONE_NEWNET`参数创建出一个网络命名空间。

**实现步骤**

* Docker Daemon首次启动时都会创建一个虚拟网桥`docker0`，通常地址为`172.x.x.x`，在私有的网络空间中给这个网络分配一个子网
* 由Docker创建处理的每个容器，都会创建一个虚拟以太设备对`veth pair`，一端关联到网桥，另一端使用Namespace技术映射到容器内的`eth0`设备，然后从网桥的地址段内给`eth0`接口分配一个IP地址。

一般情况下，宿主机IP与dockerIP、容器IP是不同的IP段，默认情况下，外部看不到docker0和容器IP，对于外部来说相当于docker0和容器的IP为内网IP。

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510578957/article/kubernetes/network/bridge.png)

**外部网络访问Docker容器**

外部访问Docker容器可以通过`NAT`的方式，Docker使用NAT的方式将容器内部的服务与宿主机的某个端口`port_1`绑定。

外部访问容器的流程如下:

* 外界网络通过宿主机的IP和映射的端口port_1来访问，`宿主机IP:port_1`
* 当宿主机收到此类请求，会通过DNAT将请求的目标IP即宿主机IP和目标端口即映射端口port_1替换成容器的IP和容器的端口port_0
* 由于宿主机上可以识别容器IP，所以宿主机将请求转发给veth pair
* veth pair将请求发送给容器内部的eth0，由容器内不得服务进行处理

**Docker容器访问外部网络**

* docker容器向外部目标IP和目标端口port_2发起请求，请求报文中的源IP为容器IP
* 请求通过容器内部的eth0到veth pair的另一端docker0网桥
* docker0网桥通过数据报转发功能将请求转发到宿主机的eth0
* 宿主机处理请求时通过SNAT将请求中的源IP换成宿主机eth0的IP
* 处理后的报文通过请求的目标IP发送到外部网络

使用NAT的方式可能会带来性能的问题，影响网络传输的效率

<br>

### **3.2 host模式**

host模式并没有给Docker容器创建一个隔离的网络环境，而是和宿主机共用一个网络命名空间，容器使用宿主机的eth0和外界进行通信，同样容器也共用宿主机的端口资源，即分配端口可能存在与宿主机已分配的端口冲突的问题。

实现的方式即父进程在创建子进程的时候不传`CLONE_NEWNET`参数，从而和宿主机共享一个网络空间

host模式没有通过NAT的方式进行转发因此性能上更好，但是不存在隔离型，可能导致端口冲突

<br>

### **3.3 container模式**

container模式即docker容器可以使用其他容器的网络命名空间，即和其他容器处于同一个网络命名空间。

步骤:

* 查找其他容器的网络命名空间
* 新创建的容器的网络命名空间使用其他容器的网络命名空间

通过和其他容器共享网络命名空间的方式，可以让不同的容器之间处于相同的网络命名空间，可以直接通过localhost的方式进行通信，简化了强关联的多个容器之间的通信问题

kubernetes中的Pod概念就是一组容器共享一个network namespace来实现Pod内多个容器使用localhost进行通信的

<br>

### **3.4 none模式**

none模式即不为容器创建任何的网络环境，用户可以根据自己的需要手动去创建不同的网络定制配置。

<br>

## **4. Kubernetes网络模型**

* 每个Pod都拥有一个独立的IP地址，而且假定所有Pod都在一个可以直接连通的、扁平化的网络空间中，不管是否运行在同一个Node上都可以通过Pod的IP来访问
* kubernetes中的Pod是最小粒度的IP。同一个Pod内所有容器共享一个网络堆栈，该模型称之为IP-per_Pod模型
* Pod由docker0实际分配的IP，Pod内部可以看到的IP地址和端口与外部保持一致。同一个Pod内的不同容器共享网络，可以通过localhost来访问对方的端口，类似同一个VM内的不同进程
* IP-per-Pod模型从端口分配、域名解析、服务发现、负载均衡、应用配置等角度看，Pod可以被看作是一台独立的VM或者物理机

<br>

### **4.1 kubernetes对集群的网络要求**

* 所有容器都可以不用NAT的方式同别的容器通信
* 所有节点都可以在不同NAT的方式下同所有容器通信，反之亦然
* 容器的地址和别人看到的地址是同一个地址


![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510578957/article/kubernetes/network/network-arch.png)

<br>

### **4.2 kubernetes集群IP概念汇总**

从集群外部到集群内部:

| IP类型 | 说明 
| :---- | :---- |
| Proxy-IP | 代理层公网地址IP，外部访问应用的网关服务器|
| Service-IP | Service的固定虚拟IP，Service-IP是内部，外部无法寻址到 |
| Node-IP | 容器宿主机的主机IP |
| Container-Bridge-IP | 容器网桥IP`docker0`，容器的网络都需要通过容器网桥转发 |
| Pod-IP | Pod的IP，等效于Pod中网络容器的Contaioner-IP |
| Container-IP | 容器的IP，容器的网络是个隔离的网络空间 |

<br>

## **5. Kubernetes的网络实现**

kubernetes网络场景:
* 容器与容器之间的直接通信
* Pod与Pod之间的通信
* Pod到Service之间的通信
* 集群外部与内部组件之间的通信

<br>

### **5.1 Pod网络**

Pod作为kubernetes的最小调度单元，Pod是容器的集合，是一个逻辑概念，Pod包含的容器都运行在同一个宿主机上，这些容器将拥有同样的网络空间，容器之间能够互相通信，它们能够在本地访问其它容器的端口。 实际上Pod都包含一个网络容器，它不做任何事情，只是用来接管Pod的网络，业务容器通过加入网络容器的网络从而实现网络共享。Pod网络本质上还是容器网络，所以Pod-IP就是网络容器的Container-IP。

一般将容器云平台的网络模型打造成一个扁平化网络平面，在这个网络平面内，Pod作为一个网络单元同Kubernetes Node的网络处于同一层级。

<br>

### **5.2 Pod之间的通信**

同一个Pod之间的不同容器因为共享同一个网络命名空间，所以可以直接通过localhost直接通信。

#### **5.2.1 同一个Node上的Pod之间的通信**

同一个Node内，不同的Pod都有一个全局IP，可以直接通过Pod的IP进行通信。Pod地址和docker0在同一个网段。

在pause容器启动之前，会创建一个虚拟以太网接口对（veth pair），该接口对一端连着容器内部的eth0 ，一端连着容器外部的vethxxx，vethxxx会绑定到容器运行时配置使用的网桥bridge0上，从该网络的IP段中分配IP给容器的eth0。

当同节点上的Pod-A发包给Pod-B时，包传送路线如下：

Pod-A的eth0 -> Pod-A的vethxxx -> bridge0 -> Pod-B的vethxxx -> Pod-B的eth0

因为相同节点的bridge0是相通的，因此可以通过bridge0来完成不同pod直接的通信，但是不同节点的bridge0是不通的，因此不同节点的pod之间的通信需要将不同节点的bridge0给连接起来。

<br>

#### **5.2.2 不同的Node上Pod之间的通信**

不同的Node之间，Node的IP相当于外网IP，可以直接访问，而Node内的docker0和Pod的IP则是内网IP，无法直接跨Node访问。需要通过Node的网卡进行转发。

所以不同Node之间的通信需要达到两个条件：

* 对整个集群中的Pod-IP分配进行规划，不能有冲突（可以通过第三方开源工具来实现，例如flannel）
* 将Node-IP与该Node上的Pod-IP关联起来，通过Node-IP再转发给Pod-IP

不同节点的Pod之间的通信需要将不同节点的bridge0给连接起来。连接不同节点的bridge0的方式有好几种，主要有overlay和underlay，或常规的三层路由。

不同节点的bridge0需要不同的IP段，保证Pod IP分配不会冲突，节点的物理网卡eth0也要和该节点的网桥bridge0连接。因此，节点a上的pod-a发包给节点b上的pod-b，路线如下：

节点A上的Pod-A的eth0 -> 节点A上的Pod-A的vethxxx -> 节点A的bridge0 -> 节点A的eth0 -> 节点B的eth0 -> 节点B的bridge0 -> 节点B上的Pod-B的vethxxx -> 节点B上的Pod-B的eth0

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1510578957/article/kubernetes/network/pod-network.png)

**Pod间实现通信**

Pod1和Pod2（同主机），Pod1和Pod3(跨主机)能够通信

实现: 因为Pod的Pod-IP是Docker网桥分配的，Pod-IP是同Node下全局唯一的。所以将不同Kubernetes Node的 Docker网桥配置成不同的IP网段即可。

**Node与Pod间实现通信**

Node1和Pod1/ Pod2(同主机)，Pod3(跨主机)能够通信

实现: 在容器集群中创建一个覆盖网络(Overlay Network)，联通各个节点，目前可以通过第三方网络插件来创建覆盖网络，比如Flannel和Open vSwitch等。

不同节点间的Pod访问也可以通过calico形成的Pod IP的路由表来解决。

<br>

### **5.3 Service网络**

Service的就是在Pod之间起到服务代理的作用，对外表现为一个单一访问接口，将请求转发给Pod，Service的网络转发是Kubernetes实现服务编排的关键一环。Service都会生成一个虚拟IP，称为Service-IP， Kuberenetes Porxy组件负责实现Service-IP路由和转发，在容器覆盖网络之上又实现了虚拟转发网络。

Kubernetes Porxy实现了以下功能：

* 转发访问Service和Service-IP的请求到Endpoints
* 监控Service和Endpoints的变化，实时刷新转发规则
* 负载均衡能力

<br>