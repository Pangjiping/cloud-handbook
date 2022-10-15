# **高并发TCP连接中大量的TIME_WAIT状态优化**

## **查看TIME_WAIT状态**

```bash
$ ss -s
Total: 296 (kernel 377)
TCP:   42 (estab 5, closed 29, orphaned 1, synrecv 0, timewait 17/0), ports 0

Transport Total     IP        IPv6
*         377       -         -        
RAW       0         0         0        
UDP       7         4         3        
TCP       13        8         5        
INET      20        12        8        
FRAG      0         0         0
```

可以看到有17个连接在`TIME_WAIT`状态

<br>

## **TIME_WAIT状态过多的危害**

* 在socket的TIME_WAIT状态结束之前，该socket所占用的本地端口号将一直无法释放
* 在高并发并且采用短连接方式进行交互的系统运行一段时间后，系统中就会存在大量的TIME_WAIT状态。如果TIME_WAIT状态把系统所有可用端口
都占完了且尚未被系统回收时，就会出现无法向服务端创建新的socket连接的情况。此时系统几乎停转，任何链接都不能建立
* 大量的time_wait状态也会消耗系统一定的fd，内存和cpu资源

<br>

## **如何优化TIME_WAIT状态过多的问题**

### **1. 调整内核参数**

/etc/sysctl.conf文件

```bash
net.ipv4.tcp_syncookies = 1 表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1 表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_recycle = 1 表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。
net.ipv4.tcp_fin_timeout =  修改系统默认的 TIMEOUT 时间
net.ipv4.tcp_max_tw_buckets = 5000 表示系统同时保持TIME_WAIT套接字的最大数量，(默认是18000). 当TIME_WAIT连接数量达到给定的值时，所有的TIME_WAIT连接会被立刻清除，并打印警告信息。但这种粗暴的清理掉所有的连接，意味着有些连接并没有成功等待2MSL，就会造成通讯异常。一般不建议调整
net.ipv4.tcp_timestamps = 1(默认即为1)60s内同一源ip主机的socket connect请求中的timestamp必须是递增的。也就是说服务器打开了 tcp_tw_reccycle了，就会检查时间戳，如果对方发来的包的时间戳是乱跳的或者说时间戳是滞后的，那么服务器就会丢掉不回包，现在很多公司都用LVS做负载均衡，通常是前面一台LVS，后面多台后端服务器，这其实就是NAT，当请求到达LVS后，它修改地址数据后便转发给后端服务器，但不会修改时间戳数据，对于后端服务器来说，请求的源地址就是LVS的地址，加上端口会复用，所以从后端服务器的角度看，原本不同客户端的请求经过LVS的转发，就可能会被认为是同一个连接，加之不同客户端的时间可能不一致，所以就会出现时间戳错乱的现象，于是后面的数据包就被丢弃了，具体的表现通常是是客户端明明发送的SYN，但服务端就是不响应ACK，还可以通过下面命令来确认数据包不断被丢弃的现象，所以根据情况使用

其他优化：

net.ipv4.ip_local_port_range = 1024 65535 增加可用端口范围，让系统拥有的更多的端口来建立链接，这里有个问题需要注意，对于这个设置系统就会从1025~65535这个范围内随机分配端口来用于连接，如果我们服务的使用端口比如8080刚好在这个范围之内，在升级服务期间，可能会出现8080端口被其他随机分配的链接给占用掉，这个原因也是文章开头提到的端口被占用的另一个原因
net.ipv4.ip_local_reserved_ports = 7005,8001-8100 针对上面的问题，我们可以设置这个参数来告诉系统给我们预留哪些端口，不可以用于自动分配。
```

### **2. 修改短连接为长连接**

长连接比短连接从根本上减少了关闭连接的次数，减少了TIME_WAIT状态的产生数量，在高并发的系统中，这种方式的改动非常有效果，可以明显减少系统TIME_WAIT的数量。

[Q: 对于redis这种场景，没有办法做长连接怎么办?]

<br>