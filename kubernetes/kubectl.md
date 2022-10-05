# **kubectl**

## **安装kubectl**
---

下载最新的发行版，for apple silicon

```bash
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
```

如果需要下载某个指定版本，用指定版本号即可
```bash
$ curl -LO "https://dl.k8s.io/release/v1.25.0/bin/darwin/arm64/kubectl"
```

将kubectl置为可执行文件

```bash
$ chmod +x ./kubectl
```

将可执行文件kubectl移动到系统可寻址路径PATH内的一个位置

```bash
$ sudo mv ./kubectl /usr/local/bin/kubectl
$ sudo chown root: /usr/local/bin/kubectl
```

测试下kubectl

```bash
$ kubectl version --client --output=yaml
```

<br>

## **kubectl常用指令集**
---
TODO

<br>

## **Reference**
---

* [在macos上安装kubectl](https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-macos/)
* [在linux上安装kubectl](https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-linux/)
* [在windows上安装kubectl](https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-windows/)

<br>