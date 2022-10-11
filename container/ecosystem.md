# **容器生态系统**

## **容器生态系统**

下图展示了Docker、Kubernetes、CRI、OCI、contrainerd和runc在容器生态系统中是如何结合的。

![img](https://pic3.zhimg.com/80/v2-9b195f8c713cf2a33ad142f269585e7e_1440w.webp)

其工作流程简单来讲是这样的:

* Docker和Kubernetes等工具来运行一个容器时会调用容器运行时（ORI）比如containerd，CRI-O
* 通过容器运行时来完成容器的创建、运行和销毁等实际工作
  * Docker使用containerd作为运行时，Kubernetes支持containerd、CRI-O等多种容器运行时
  * 这些容器运行时都遵循了OCI规范，并通过runc来实现与操作系统内核交互来完成容器的创建和运行

<br>

## **Docker**

Docker开启了整个容器的革命，它创造了一个很好用的工具来处理容器也叫Docker，这里最主要的要明白:
* Docker并不是唯一的容器竞争者
* 容器不与Docker这个名字紧密联系在一起

在目前的容器工具中，Docker只是其中之一，其他著名的容器工具还包括: Podman、LXC、containerd、Buildah等。

### **Docker组成**
---

Docker可以轻松地构建容器镜像，从DockerHub中拉取镜像，创建、启动和管理容器。实际上，当你使用Docker运行一个容器实际上是通过Docker守护进程、containerd和runc来运行它。

![img](https://pic3.zhimg.com/80/v2-6510f4ef31e693d6b4b6345439854c4a_1440w.webp)

为了实现这一切，Docker是由这些项目组成:
* docker-cli: 这是一个命令行工具，它是用来完成`docker pull`, `build`, `run`, `exec`等命令进行交互
* containerd: 这是一个管理和运行容器的守护进程。它推送和拉动镜像，管理存储和网络，并监督容器的运行
* runc: 这是低级别的容器运行时间（实际创建和运行容器的东西）。它包括 libcontainer，一个用于创建容器的基于 Go 的本地实现

<br>

### **Docker镜像**
---

Docker镜像实际上就是以Open Container Initiative（OCI）格式打包的镜像。

因此，如果你从DockerHub或者其他注册中心拉取一个镜像，你应该能够用docker命令使用它，或者在kubernetes集群上使用，或者用podman工具以及其他任何支持OCI镜像格式规范的工具

<br>

## **Dockershim**

在 Kubernetes 包括一个名为 dockershim 的组件，使它能够支持 Docker。但 Docker 由于比 Kubernetes 更早，没有实现 CRI，所以这就是 dockershim 存在的原因，它支持将 Docker 被硬编码到 Kubernetes 中。随着容器化成为行业标准，Kubernetes 项目增加了对额外运行时的支持，比如通过 Container Runtime Interface (CRI) 容器运行时接口来支持运行容器。因此 dockershim 成为了 Kubernetes 项目中的一个异类，对 Docker 和 dockershim 的依赖已经渗透到云原生计算基金会（CNCF）生态系统中的各种工具和项目中，导致代码脆弱。

2022 年 4 月 dockershim 将会从 Kubernetes 1.24 中完全移除。今后 Kubernetes 将取消对 Docker 的直接支持，而倾向于只使用实现其容器运行时接口的容器运行时，这可能意味着使用 containerd 或 CRI-O。这并不意味着 Kubernetes 将不能运行 Docker 格式的容器。containerd 和 CRI-O 都可以运行 Docker 格式（实际上是 OCI 格式）的镜像，它们只是无需使用 docker 命令或 Docker 守护程序。

<br>

## **Container Runtime Interface (CRI)**

CRI（容器运行时接口）是 Kubernetes 用来控制创建和管理容器的不同运行时的 API，它使 Kubernetes 更容易使用不同的容器运行时。它一个插件接口，这意味着任何符合该标准实现的容器运行时都可以被 Kubernetes 所使用。

Kubernetes 项目不必手动添加对每个运行时的支持，CRI API 描述了 Kubernetes 如何与每个运行时进行交互，由运行时决定如何实际管理容器，因此只要它遵守 CRI 的 API 即可。

![img](https://pic2.zhimg.com/80/v2-2b6d762a4ef5f118892c6420fe790f19_1440w.webp)

<br>

## **containerd**

containerd是一个来自Docker的高级容器运行时，并实现了CRI规范。它是从Docker项目中分离出来的，之后containerd被捐赠给CNCF基金会为容器社区提供创建新容器的解决方案的基础。

所以 Docker 自己在内部使用 containerd，当你安装 Docker 时也会安装 containerd。

containerd 通过其 CRI 插件实现了 Kubernetes 容器运行时接口（CRI），它可以管理容器的整个生命周期，包括从镜像的传输、存储到容器的执行、监控再到网络。

<br>