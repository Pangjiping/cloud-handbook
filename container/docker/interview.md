# **docker**

- https://www.huweihuang.com/docker-notes/

## **基础问题**

### **什么是docker**
---
“一次封装，到处运行”

解决了运行环境和配置问题的软件容器，方便做持续集成并有助于整体发布的容器虚拟化技术

![img](http://res.cloudinary.com/dqxtn0ick/image/upload/v1510577966/article/docker/dockerArch/docker-architecture.jpg)

**为什么docker比虚拟机快**

* docker比虚拟机有更小的抽象层，不需要将硬件虚拟化
* docker利用的是宿主机的内核，而不需要Guest OS

<br>

### **docker镜像加载原理**
---
* docker的镜像实际上由一层一层的文件系统组成，这种层级的文件系统UnionFS
* 其中包括root file system(bootfs)和root file system(rootfs)，在docker镜像加载中，bootfs是与宿主机共享的，而只需要加载rootfs即可
* 为什么要采用这种分层架构？---共享资源

<br>

### **Dockerfile**
---
* FROM
* RUN
* EXPOSE
* ENV
* VOLUME
* ADD/COPY
* CMD/ENTRYPOINT

**几点注意事项**
* CMD和ENTRYPOINT区别: CMD只有最后一行会生效，而且可以通过run 携参覆盖, ENTRYPOINT不会被覆盖，而是追加操作
* COPY和ADD区别: COPY完成镜像源文件的拷贝, ADD完成文件拷贝并加压安装，tar

<br>

### **docker底层技术支撑**
---
Linux 命令空间、控制组和UnionFS三大技术支撑了目前Docker的实现：

![img](https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220327164906371-1093498551.png)

* namespace: 容器隔离的基础，保证容器A看不到容器B
* cgroups控制组: 容器资源统计和隔离
* UnionFS联合文件系统: 分层镜像实现的基础

实际上Docker使用了很多Linux的隔离功能，让容器看起来是一个轻量级的虚拟机在独立运行，容器的本质就是被限制了namespace和cgroup，具有逻辑上独立的独立文件系统的一个进程

推荐阅读: https://www.cnblogs.com/aganippe/p/16064002.html

推荐阅读: https://zhuanlan.zhihu.com/p/257954941

<br>

### **docker swarm**
---
Docker Swarm是docker的本地群集。它将docker主机池转变为单个虚拟docker主机。Docker Swarm提供标准的docker API，任何已经与docker守护进程通信的工具都可以使用Swarm透明地扩展到多个主机。

<br>

### **如何监控docker容器**
---
* docker提供`docker:stats`和docker事件工具来监控docker
* docker统计数据: 当我们使用容器ID调用`docker stats`时，我们获得容器的CPU，内存使用情况等。它类似于Linux中的top命令
* Docker事件: docker事件是一个命令，用于查看docker守护程序中正在进行的活动流。一些常见的docker事件是：attach，commit，die，detach，rename，destroy等。我们还可以使用各种选项来限制或过滤我们感兴趣的事件

<br>

### **docker本地镜像放在哪里**
---
与docker相关的本地资源存在`/var/lib/docker/`目录下，其中container目录存放容器信息，graph目录存放镜像信息，aufs目录下存放具体的镜像底层文件。

<br>

### **构建docker景象应遵循的原则**
---
* 尽量选取满足需求但较小的基础系统镜像，建议选择debian:wheezy镜像，仅有86MB大小
* 清理编译生成文件、安装包的缓存等临时文件
* 安装各个软件时候要指定准确的版本号，并避免引入不需要的依赖
* 从安全的角度考虑，应用尽量使用系统的库和依赖
* 使用dockerfile创建镜像时候要添加.dockerignore文件或使用干净的工作目录

<br>

### **docker网络**
---
https://www.huweihuang.com/kubernetes-notes/network/docker-network.html

<br>

### **containerd和docker**
---
https://www.huweihuang.com/kubernetes-notes/runtime/runtime.html

<br>
