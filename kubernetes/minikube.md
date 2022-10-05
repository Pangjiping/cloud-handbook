# minikube

## **什么是minikube**
---

minikube可以用来快速启动一个本地kubernetes集群，用来开发和学习。

<br>

## **macos部署minikube**
---

#### 1. 环境检查
* 2 CPUs or more
* 2GB of free memory
* 20GB of free disk space
* Internet connection
* Container runtime. Such as `docker`

#### 2. MacOS安装minikube
推荐使用二进制的方式安装

```bash
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
$ sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

检查minikube版本
```
$ minikube version
minikube version: v1.27.0
commit: 4243041b7a72319b9be7842a7d34b6767bbdac2b
```

#### 3. 启动一个kubernetes集群
运行下列指令快速拉起一个kubernetes集群，在启动之前保证docker已经启动了。整个过程大概需要几分钟

```bash
$ minikube start
```

#### 4. 使用kubectl与集群交互
请确保已经安装了kubectl

```bash
$ kubectl get po -A
```


<br>

## **Reference**
---

* [minikube start](https://minikube.sigs.k8s.io/docs/start/)

<br>