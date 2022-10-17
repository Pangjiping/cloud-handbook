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

