# **prometheus监控平台的部署与监控**

## **1. prometheus简介**

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220518211500615-658317383.png)

Prometheus是一个开源的系统监控和报警系统，在2012年由SoundCloud创建，并于2015年正式发布

2016年，Prometheus项目正式加入CNCF基金会，成为继kubernetes之后第二个在CNCF托管的项目，现在已经广泛用于容器和微服务领域

Prometheus本身是基于go开发的一套开源的系统监控报警框架和时序数据库（TSDB）

Prometheus的监控功能很完善和全面，性能支持上万规模的集群

Prometheus网站：https://prometheus.io/

Prometheus官网文档：https://prometheus.io/docs

Prometheus代码仓库：https://github.com/prometheus

Prometheus中文文档：https://www.prometheus.wang

Prometheus exporters：https://prometheus.io/docs/instrumenting/exporters/

Prometheus exporter golang客户端库：https://github.com/prometheus/client_golang

Prometheus的特点如下：
* 支持多维数据模型：由度量名和键值对组成的时间序列数据
* 内置时间序列数据库TSDB
* 支持PromQL（Prometheus Query Language）查询语言，可以完成非常复杂的查询和分析，对图表展示和告警非常有意义
* 支持HTTP的PULL方式采集时间序列数据
* 支持PushGateway采集瞬时任务的数据
* 支持服务发现和静态配置两种方式发现目标
* 多种可视化和仪表盘，支持第三方dashboard，比如Grafana
 

数据特点：
* 监控指标，采用独创的指标格式，我们称之为Prometheus格式，这个格式在监控场景中非常常见
* 数据标签，支持多维度标签，每个独立的标签组合都代表一个独立的时间序列
* 数据处理，Prometheus内部支持多种数据的聚合、切割、切片等功能
* 数据存储，Prometheus支持双精度浮点型数据存储

适用场景：
* Prometheus非常适合记录任何纯数字时间序列。它既适合以机器为中心的监控场景，又适合高度动态的面向服务的体系结构的监控场景
* 在微服务场景中，它对多维数据收集和查询的支持是一种特别的优势
* Prometheus的设计旨在提升可用性，使其省委中断期间要使用的系统，以快速诊断问题
* 每个Prometheus服务器都是独立的，而不依赖于网络存储或其他远程服务

<br>

## **2. prometheus架构**

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220518214536586-992606033.png)

Prometheus监控是一个监控体系，而Prometheus server只包含Retrieval、TSDB、HTTP server三个组件

Prometheus的主要模块包括：Prometheus server、exporters、PushGateway、PromQL、Alertmanager以及图形化界面

主要组件：
* Prometheus：时序数据存储、监控指标管理
* 可视化：Prometheus webUI、Grafana可视化套件
* 数据采集：exporters为当前客户端暴露出符合Prometheus规格的数据指标、PushGateway为push模式下的数据采集工具
* 监控目标：服务发现，包括文件方式、DNS方式、console方式、kubernetes方式
* 告警：Alertmanager

其中TSDB支持存储60天的数据，如果想要永久存储监控数据的话需要增加一个时序数据库后端，比较典型的是InfluxDB

Retrival负责获取监控数据，也就是Prometheus targets，通常采用的是pull模式

<br>

### **2.1 pull和push**

本质上来讲Prometheus只支持pull的方式来获取监控数据

那么push又从何而来的呢？对于一些瞬时任务，比如一个存在时间极短的job，pull的方式显然是不太能够抓取到这些数据的

Prometheus所采用的方式就是部署一个PushGateway，job在执行完成之后将数据push到这个网关代理，而Prometheus将从PushGateway中pull数据

pull模式的特点：
* 被监控方提供一个server，并负责维护
* 监控方控制采集频率

第一点对用户来说要求更高了，但是好处很多，比如pull不到数据本身就说明节点存在故障；比如监控指标自然而然由用户自己维护，使得标准化很简单

第二点更为重要，那就是在监控体系对metric采集的统一和稳定有了可靠的保证，对于数据量大的情况下很重要

同样pull模式的缺点在于需要服务发现模块来动态发现被监控对象，同时被监控方和Prometheus可能存在数据维护不同步的情况，造成一定的信息丢失和不准确

<br>

## **3. prometheus数据模型**

Prometheus中存储的数据为时间序列，即基于同一度量标准或者同一时间维度的数据流

除了时间序列数据的正常存储外，Prometheus还会基于原始数据临时生成新的时间序列数据，用于后续查询的依据或结果

每个时间序列都是由metric名称和标签（可选键值对）组成的唯一标识

<br>

### **3.1 metric**

* 该名字必须有意义，用于表示metric的一般性功能，例如：http_requests_total表示http请求的总数
* metric名字由ASCII字符、数字、下划线和冒号组成，且必须满足正则表达式a-zA-Z:*的查询请求
* 注意：冒号是为用户自定义的记录规则保留的

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519090206854-2078638225.png)

<br>

### **3.2 标签**

标签是以键值对的形式存在的，不同的标签用于表示时间序列的不同维度标识

基本格式：

```c#
<metric name>{<label name>=<label value>, ...}
 
# 示例
http_requests_total{method="POST", endpoint="/api/tracks"}
# 解析：
# http_requests_total{method="POST"}表示所有http请求中的POST请求
# endpoint="/api/tracks"表示请求的url地址是/api/tracks
```

* 标签中的key由ASCII字符、数字以及下划线组成，且必须要满足正则表达式a-zA-Z:*
* 标签值可以包含任何Unicode字符，标签值为空被认为等同于不存在的标签

查询语言允许基于这些维度进行过滤和聚合

更改任何标签值，包括添加或删除标签，都会创建一个新的时间序列

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519091115071-2071751535.png)

<br>

## **4. prometheus部署**

<br>

### **4.1 常见的部署方式**

**包安装**

RHEL系统：https://packagecloud.io/app/prometheus-rpm/release/search

Ubuntu和Debian可直接使用apt命令安装

 

**二进制安装**

https://prometheus.io/download/

 

**docker安装**

https://prometheus.io/docs/prometheus/latest/installation/

 

**k8s operator安装**

https://github.com/coreos/kube-prometheus

<br>

### **4.2 docker部署prometheus**

```bash
$ docker run -d --name prometheus -p 9090:9090 prom/prometheus
```

镜像拉取成功后可以查看 Prometheus是否正在运行

```bash
$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                                       NAMES
7bb063c228ed   prom/prometheus   "/bin/prometheus --c…"   5 seconds ago   Up 3 seconds   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp   prometheus
```

访问`ip+9090`就可以打开Prometheus的webUI

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519093110519-1305982652.png)

访问`ip+9090/metrics`可以看到Prometheus拉取的监控指标数据

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519093259403-2015389455.png)

<br>

### **4.3 二进制部署prometheus**

```bash
$ cd /usr/local
$ wget https://github.com/prometheus/prometheus/releases/download/v2.19.2/prometheus-2.19.2.linux-amd64.tar.gz
$ tar xvf prometheus-2.19.2.linux-amd64.tar.gz
$ ln -s prometheus-2.19.2.linux-amd64 prometheus
$ cd prometheus/
$ mkdir bin conf data
$ mv prometheus promtool bin/
$ mv prometheus.yml conf/
$ useradd -r -s /sbin/nologin prometheus
$ chown -R prometheus.prometheus /usr/loacl/prometheus/
```

将Prometheus添加到环境变量

```bash
$ cat /etc/profile.d/prometheus.sh
$ export PROMETHEUS_HOME=/usr/local/prometheus
$ export PATH=${PROMETHEUS_HOME}/bin:$PATH
$ source /etc/profile.d/prometheus.sh
```

查看配置文件，默认可不修改

```bash
$ grep -Ev "^ *#|^$" /usr/local/prometheus/conf/prometheus.yml
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
alerting:
  alertmanagers:
  - static_configs:
    - targets:
rule_files:
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
```

检查配置文件是否正确

```bash
$ promtool check config /usr/local/prometheus/conf/prometheus.yml
Checking /usr/local/prometheus/conf/prometheus.yml
  SUCCESS: 0 rule files found
```

创建service文件

```bash
$ vim /lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network.target
 
[Service]
Restart=on-failure
User=prometheus
WorkingDirectory=/usr/local/prometheus/
ExecStart=/usr/local/prometheus/prometheus --config.file=/usr/local/prometheus/conf/prometheus.yml
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65535
 
[Install]
WantedBy=multi-user.target
```

启动Prometheus server

```bash
$ systemctl daemon-reload
$ systemctl enable --now prometheus.service
$ ss -tnlp | grep prometheus
```

再次访问ip:9090就可以看到Prometheus的webUI界面

完整的安装脚本可参考[install_prometheus.sh](https://github.com/Pangjiping/cloud-handbook/blob/main/prometheus/install_prometheus.sh)

<br>

## **5. Node exporter**

安装node exporter用于收集各k8s节点上的监控指标数据，监听端口为9100

官方下载：https://prometheus.io/download/

**下载并解压**

```bash
$ wget -P /usr/local/ https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz
$ cd /usr/local
$ tar xvf node_exporter-1.2.2.linux-amd64.tar.gz
$ ln -s node_exporter-1.2.2.linux-amd64 node_exporter
$ cd node_exporter
$ mkdir bin
$ mv node_exporter bin/
```

**准备service文件**

```bash
$ vim  /lib/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target
 
[Service]
Type=simple
ExecStart=/usr/local/node_exporter/bin/node_exporter
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

**启动exporter服务**

```bash
$ systemctl daemon-reload
$ systemctl enable --now node_exporter.service
$ systemctl is-active node_exporter
$ ss -ntlp | grep node_exporter
```

node_exporter默认在9100端口服务，浏览器访问`ip:9100`可以看到node_exporter收集到的metric数据

完整的安装脚本可参考[install_node_exporter.sh](https://github.com/Pangjiping/cloud-handbook/blob/main/prometheus/install_node_exporter.sh)

<br>

## **6. prometheus采集监控数据**

配置promtheus通过node exporter组件采集node节点的监控指标数据

promtheus的服务发现可以直接修改其配置文件，也可以在服务注册中心发现自己需要监控的节点

<br>

### **6.1 修改prometheus的配置文件**

```bash
$ vim /usr/local/prometheus/conf/prometheus.yml
# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093
 
# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"
 
# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'
 
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
 
    static_configs:
    - targets: ['localhost:9090']
```

其中的scrape_configs就是我们的监控节点信息，如果想要加上一个node_exporter任务，只需要再添加一个job即可

```bash
- job_name: "prometheus"
   static_configs:
      - targets: ["localhost:9090"]
  - job_name: 'node_exporter'   #添加以下行,指定监控的node exporter节点
   static_configs:
    - targets: ['10.0.0.104:9100','10.0.0.105:9100','10.0.0.106:9100'] 
#属性解析：
#新增一个job_name 和 static_configs的属性
#targets 就是前面基本概念中提到的instance，格式就是"ip:port"
```

然后重启prometheus服务

```bash
$ systemctl restart prometheus
```

<br>

### **6.2 prometheus验证node节点状态**

浏览器访问普罗米修斯webUI，打开targets页签就可以看到我们监控的节点信息

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220520111150017-1983836219.png)

<br>

## **7. Grafana**

Grafana是一个开源的度量分析与可视化套件，它基于go语言开发，经常被用作基础设施的时间序列数据和应用程序分析的可视化

Grafana不仅仅支持很多类型的时序数据库数据源，比如Graphite、InfluxDB、Prometheus、Elasticsearch等，虽然每种数据源都有独立的查询语言和能力，但是Grafana的查询编辑器支持所有的数据源，而且能很好的支持每种数据源的特性。

通过该查询编辑器可以对所有数据进行整合，而且还可以在同一个dashboard上进行综合展示。

默认监听与TCP的3000端口，支持集成其他认证服务，且能够通过/metrics输出内建指标

可以在https://grafana.com/dashboards/ 页面查询到我们想要的各种dashboard模版

<br>

### **7.1 Grafana部署**

在prometheus server的服务器上部署Grafana即可

```bash
# ubuntu系统
$ wget https://dl.grafana.com/enterprise/release/grafana-enterprise_8.2.1_amd64.deb
$ apt -y install ./grafana-enterprise_8.2.1_amd64.deb
```

启动服务

```bash
$ systemctl daemon-reload
$ systemctl enable --now grafana-server.service
$ ss -ntulp | grep grafana
```

<br>

### **7.2 配置Grafana**

登陆grafana，默认登陆用户名和密码为admin/admin

点击添加数据源“Add your first data source”

选择Prometheus，在setting界面配置prometheus信息即可

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220520131405988-1093278902.png)

在dashboards界面选择想用的dashboard模版，选择任意模版后可以查看效果

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220520131737286-406106321.png)

我们也可以选择一个任意的模版，通过import导入我们想用的模版即可

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220520132057368-1539090615.png)

<br>

## **Reference**
* https://time.geekbang.org/column/article/72281
* https://time.geekbang.org/column/article/73156
* https://prometheus.io/docs/introduction/overview/