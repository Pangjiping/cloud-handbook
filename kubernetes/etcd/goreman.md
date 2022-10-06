# **goreman管理本地etcd集群**

环境：MacOS

<br>

## **1. 安装etcd**

克隆etcd源码

v3.5.0 是etcd版本，想要下载指定版本在此指定即可

```bash
$ mkdir $GOPATH/src/github.com/etcd-io
$ cd $GOPATH/src/github.com/etcd-io
$ git clone -b v3.5.0 https://github.com/etcd-io/etcd.git
```

编译

```bash
$ cd etcd
$ ./build.sh
```

会下载依赖包执行编译，确保网络环境可以下载github上的依赖包

编译成功页面

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220513103808224-7214225.png)

将etcd添加到系统路径

```bash
$ vim ~/.zshrc
$ export PATH="$PATH:$GOPATH/src/github.com/etcd-io/etcd/bin"
$ source ~/.zshrc
```

测试etcd是否安装成功

```bash
$ etcd --version
 
etcd Version: 3.5.0
Git SHA: 946a5a6f2
Go Version: go1.17.7
Go OS/Arch: darwin/amd64
```

<br>

## **2. 安装goreman**

安装goremane

```bash
$ go install github.com/mattn/goreman@latest
```

检查goreman是否安装成功

```bash
$ goreman
Tasks:
  goreman check                      # Show entries in Procfile
  goreman help [TASK]                # Show this help
  goreman export [FORMAT] [LOCATION] # Export the apps to another process
                                       (upstart)
  goreman run COMMAND [PROCESS...]   # Run a command
                                       start
                                       stop
                                       stop-all
                                       restart
                                       restart-all
                                       list
                                       status
  goreman start [PROCESS]            # Start the application
  goreman version                    # Display Goreman version
 
Options:
  -b uint
    	base number of port (default 5000)
  -basedir string
    	base directory
  -exit-on-error
    	Exit goreman if a subprocess quits with a nonzero return code
  -exit-on-stop
    	Exit goreman if all subprocesses stop (default true)
  -f string
    	proc file (default "Procfile")
  -logtime
    	show timestamp in log (default true)
  -p uint
    	port (default 8555)
  -rpc-server
    	Start an RPC server listening on 0.0.0.0 (default true)
  -set-ports
    	False to avoid setting PORT env var for each subprocess (default true)
```

<br>

## **3. 利用goreman启动本地三节点etcd集群**

编写Procfile文件，可参考etcd代码库里面的写法

```bash
$ cd ~
$ vim Procfile
```

在Procfile文件中写入以下指令

```bash
etcd1: etcd --name infra1 --listen-client-urls http://127.0.0.1:12379 --advertise-client-urls http://127.0.0.1:12379 --listen-peer-urls http://127.0.0.1:12380 --initial-advertise-peer-urls http://127.0.0.1:12380 --initial-cluster-token etcd-cluster-1 --initial-cluster 'infra1=http://127.0.0.1:12380,infra2=http://127.0.0.1:22380,infra3=http://127.0.0.1:32380' --initial-cluster-state new --enable-pprof --logger=zap --log-outputs=stderr
etcd2: etcd --name infra2 --listen-client-urls http://127.0.0.1:22379 --advertise-client-urls http://127.0.0.1:22379 --listen-peer-urls http://127.0.0.1:22380 --initial-advertise-peer-urls http://127.0.0.1:22380 --initial-cluster-token etcd-cluster-1 --initial-cluster 'infra1=http://127.0.0.1:12380,infra2=http://127.0.0.1:22380,infra3=http://127.0.0.1:32380' --initial-cluster-state new --enable-pprof --logger=zap --log-outputs=stderr
etcd3: etcd --name infra3 --listen-client-urls http://127.0.0.1:32379 --advertise-client-urls http://127.0.0.1:32379 --listen-peer-urls http://127.0.0.1:32380 --initial-advertise-peer-urls http://127.0.0.1:32380 --initial-cluster-token etcd-cluster-1 --initial-cluster 'infra1=http://127.0.0.1:12380,infra2=http://127.0.0.1:22380,infra3=http://127.0.0.1:32380' --initial-cluster-state new --enable-pprof --logger=zap --log-outputs=stderr
```

开始启动etcd集群

```bash
$ goreman -f Procfile start
```

查看集群状态

三个etcd节点分别在12379、22379、32379三个端口来监听请求

```bash
$ etcdctl --write-out=table --endpoints=localhost:12379 member list
```

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220513105853868-917546445.png)

关闭某个节点

```bash
$ goreman run stop etcd2
```

重启某个节点

```bash
$ goreman run restart etcd2
```

向节点中插入数据

注意要指明一个etcd节点，否则默认向2379端口发送请求，而本地2379是没有etcd节点的

get/watch同理，就是一些etcd的简单命令行操作了，加上终端信息就行

```bash
$ etcdctl put hello world --endpoints http://localhost:12379
```

<br>