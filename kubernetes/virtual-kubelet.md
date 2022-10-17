# **virtual-kubelet**

## **1. 简介**

virtual kubelet是Kubernetes kubelet的一种实现，作为一种虚拟的kubelet用来连接kubernetes集群和其他平台的API。

这允许kubernetes的节点由其他提供者(provider)提供支持，这些provider例如serverless平台（ASK、AWS Fargate）

<br>

## **2. 架构图**

![img](https://res.cloudinary.com/dqxtn0ick/image/upload/v1566560767/article/kubernetes/virtual-kubelet/vk-diagram.svg)

<br>

## **3. 功能**

virtual kubelet提供一个可以自定义kubernetes node的依赖库。

目前支持的功能如下:
* 创建、删除、更新pod
* 容器的日志、exec命令、metrics
* 获取Pod、Pod列表、Pod status
* Node的地址、容量、daemon
* 操作系统
* 自定义virtual network

<br>

## **4. Providers**

virtual kubelet提供一个插件式的provider接口，让开发者可以自定义实现传统kubelet的功能。自定义的provider可以用自己的配置文件和环境参数。

自定义的provider必须提供以下功能：
* 提供pod、容器、资源的生命周期管理的功能
* 符合virtual kubelet提供的API
* 不直接访问k8s apiserver，定义获取数据的回调机制，例如configmap、secrets

<br>