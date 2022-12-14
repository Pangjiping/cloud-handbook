# **Redis**

## **基础问题**
---
### **为什么要用redis**
---

高性能：我们用MySQL查询数据时，需要从磁盘进行查找，速度是比较慢的，如果我们经常对该值进行查找，则会一遍一遍的请求MySQL数据库，但是如果我们将其存入缓存，再次请求时，因为是直接访问内存，速度是极快，当数据库的内容发生改变时，只需改变缓存的值即可。

高并发：直接操作缓存能够承受的请求是远远大于直接访问数据库的，所以我们可以将部分值存到缓存中去，当用户请求时直接从缓存中获取即可。

<br>

### **Redis数据类型**
---

* string
* list - 消息队列，微博TimeLine
* hash - 存储、读取、修改用户属性
* set - 共同好友、二度好友
* zset - 带有权重的元素

<br>

### **Redis底层实现**
---

* string - SDS
* list - quicklist
* hash - listpack, 哈希表
* set - 哈希表, 整数集合
* zset - listpack, 跳表

<br>

### **跳表的实现**
---

* 支持O(logN)查找
* zset对象在使用跳表作为底层结构时，zset对象结构的指针会指向zset结构，它包含两个数据结构，一个是跳表，一个是哈希表。这样的好处是既能够进行高效范围查询，又能进行高效单点查询
* 跳表是在链表基础上改进而来的，实现了一种【多层】的有序链表

![img](https://pic1.zhimg.com/v2-d679e616dd3312da3d002d555e3c0b7c_r.jpg)

<br>

### **rehash的实现**
---
* O(1) key-value查询
* 解决哈希冲突
	- 链式哈希
		- 哈希表的节点不仅包含指向键和值的指针，还包含了指向下一个哈希表节点的指针，这个指针可以将多个哈希值相同的键值对连接起来，解决哈希冲突
		- 当然链式哈希增加了平均时间复杂度，当发生冲突的key增多时，会采用 rehash机制
	- rehash
		- 其实在redis的dict结构体中定义了两个hashtable
		- 在正常服务请求阶段，只会启用ht1，而不会给ht2分配内存
		- 当触发rehash操作时
			- 1. 为ht2分配空间，一般会比ht1大2倍
			- 2. 将ht1数据迁移到ht2中，如果ht1的数据量特别大，会产生大量数据拷贝，造成redis阻塞
			- 3. ht1的空间被释放，ht2作为ht1继续工作，然后为ht2创建一个空白哈希为下次rehash做准备
	- 渐进式rehash
		- 1. 新增数据直接添加在ht2中
		- 2. 查询数据在两个ht中同时进行，当在ht1查询到数据时，会将这个索引位置上所有的key-value迁移到ht2上
	- rehash触发条件
		- 主要是和负载因子（load factor）有关
		- load factor = ht已保存的节点数量/ht大小
		- 当load factor >= 1，并且redis没有在执行bgsave或者gbrewiteaof命令，就会进行rehash
		- 当load factor >=5，不管有没有执行RDB或者AOF，就会执行rehash

<br>

### **缓存分类**
---

* 只读缓存：缓存只负责读，任何写操作都会直接操作在数据库上，然后删除缓存里的数据，然后下次再请求数据时，发现缓存内没有，则重新请求数据库，这样缓存内存在的数据仍为新数据。

* 读写缓存：读写缓存，顾名思义，其写操作也会落到缓存上，会在缓存中进行修改，但是我们要考虑这个情况，那就是我们修改了缓存，数据库宕机的情况。则会造成数据不一致的情况。

然后写入数据库的时机有两种形式，一种是同步写回，一种是异步写回。

同步写回则是，缓存修改之后，立刻修改数据库，这样可能降低响应速度，但是能够保证安全性，这里我们就需要使用事务来搞定。一起执行才行，不然就会产生数据不一致的情况。

异步写回：则会缓存修改之后，找机会再进行修改数据库。

<br>

### **缓存淘汰机制**
---
* noeviction：不删除策略，内存满了返回错误
* allkeys-lru：目标所有key，删除最近最少使用
* volatile-lru：目标expire的key，删除最近最少使用
* allkeys-random：目标所有key，随机删除
* volatile-random：目标expire的key，随机删除
* volatile-ttl：目标expire的key，删除TTL短的

如何处理被淘汰的数据？

如果数据是干净数据，则直接淘汰，如果数据是脏数据，则需要先写入数据库，然后再进行淘汰，不过Redis 使用的是修改完之后，直接写入数据库，所以不会出现清理缓存的时候出现脏数据的情况。

<br>

### **数据一致性问题**
---

**一致性**
    - 缓存中有数据，那么需要和数据库一致
    - 缓存中没有数据，那么数据库中的就是新数据

**单线程环境下**
我们可以使用消息队列来搞定，将待修改的值存入消息队列，如果修改成功则删除消息队列里的数据，如果失败，则从消息队列中取出，然后继续修改。含义则是`重试`

我们平常开发中，应该优先使用先更新数据库再删除缓存的方法，这样能够减小数据库压力。因为先删缓存会有缓存缺失的情况。

**多线程环境下**
这种情况，则会出现新的问题，我们思考一下，当A线程修改了数据库，然后写入缓存，此时B线程又修改了数据库，则会导致缓存中存的仍然是旧值。还会有另外三种情况，如果在并发环境下，如果是读写问题，则会对业务影响不大，但是写写问题则会影响很大，所以这里我们可以借助`分布式锁`redlock来解决该问题。

推荐阅读：https://www.jianshu.com/p/a8eb1412471f

<br>

### **缓存击穿**
---

缓存击穿是指，针对某个访问非常频繁的热点数据的请求，无法在缓存中进行处理，紧接着，访问该数据的大量请求，一下子都发送到了后端数据库，导致了数据库压力激增，会影响数据库处理其他请求。
- 设置热点数据永远不过期

<br>

### **缓存穿透**
---

缓存雪崩和缓存击穿都是因为键过期的情况，虽然缓存中没有该数据了，但是数据库中还有，虽然会对数据库造成压力，但是还是有机会解决。

情况如下，我们访问缓存时，发现缓存中没有该数据，则去查找数据库，发现数据库中也没有该数据，这样就会给缓存和数据库造成很大的压力。

发生这种事情有两种情况

误删除：被管理员一不小心将缓存中和数据库的数据都删了

恶意攻击：另一种情况就是被别人恶意攻击，故意拿数据库和缓存中没有的数据进行发出请求。

- 设定空值和缺省值

- 使用布隆过滤器判断是否含有该键，多用于缓存更新较少的情况，因为需要同步更新布隆过滤器

- 入口处检测（前端界面过滤，过滤掉部分）

注：布隆过滤器的原理：使用N个哈希函数，得出N个哈希值，并将哈希表的N个位置标记成 1，如果已经为 1 则无需标记，判断值是否存在时，计算N个哈希值，对应的位是否存在 0 ，存在 0 则表明该值不存在。

推荐阅读：https://www.cnblogs.com/xuanyuan/p/13665170.html

<br>

### **缓存雪崩**
---

是指缓存中大量键到期，而查询量过大，发现缓存中没有该键，则会去请求后台，引起数据库压力过大甚至宕机。
解决方案
- 过期时间设置为随机，这样就不会出现短时间内大量过期的情况。
- 使用分布式数据库，分别请求不同的数据库，则会减少某一数据库的压力。
- 设置热点数据永远不过期
- 核心数据可以访问数据库，非核心直接返回，进行一个降级

<br>

### **缓存污染**
---

缓存污染的含义：某些不常被访问的数据，白白浪费内存空间
解决方法则是利用我们的缓存淘汰策略。我们来分析一下各个`缓存淘汰策略`能不能解决缓存污染的情况
- LRU 不能解决，他可以解决最久未访问的键，但是有些不常用的键，可能会偶尔被访问一次。
- LFU最近最少使用，在使用时间和使用次数上都有要求，所以则可以解决缓存污染的情况。
LFU原理，使用一个字符串，然后前半部分保存时间戳，后半部分保存使用次数。

<br>

### **为何Redis可以这么快**
---

- 内存数据库，所有操作都在内存上
- 高效的数据结构
- 单线程避免了上下文切换
- 非阻塞I/O：Redis采用epoll做为I/O多路复用技术的实现，再加上Redis自身的事件处理模型将epoll中的连接，读写，关闭都转换为了时间，不在I/O上浪费过多的时间。

Redis基于Reactor模式开发了网络事件处理器，处理器为文件处理器，然后这个是单线程的，它采用IO多路复用机制（epoll），来监听Socket，根据Socket上的事件，来处理事件，并为其分配相应的事件处理器来处理这个事件。

推荐阅读：https://blog.csdn.net/qq_14855971/article/details/113564022

<br>

### **Redis持久化**
---

* RDB
    - 在指定的时间间隔内将内存中的数据集快照写入磁盘
    - 写时复制技术，用子进程完成持久化
	- **优势**
		- 适合大规模的数据恢复
		- 对数据完整性和一致性要求不高更适合使用
		- 节省磁盘空间
		- 恢复速度快
	- **劣势**
		- 内存中的数据被克隆了一份，大致 2 倍的膨胀性需要考虑
		- 最后一次的数据可能会丢失
		- 大量数据消耗性能

RDB 持久化可以手动执行，也可以定期自动执行。不过AOF 的更新频率更高，当开启AOF持久化时，会优先使用AOF文件来还原持久化。
Redis中主要有两个命令生成Redis的RDB 文件，一个是SAVE,一个是BGSAVE文件。
其中SAVE文件会堵塞Redis服务器进程，直到文件创建完毕（不好用），`BGSAVE会派生出一个子进程来进行创建文件。`
另外需要注意的是，RDB文件的话，会随着数据量越来越大，数据量太大时，则会加大生成快照的难度。
但是我们思考一下，我们生成RDB的过程中，如果有数据发生了更改该怎么办呢？
fork 出的子进程用于生成RDB文件，然后在生成过程中，如果有写操作，则让主进程将这块数据复制一份，在复制份上进行写。
我们可以通过使用命令，设置BGSAVE每隔一段时间执行。但是这个时间设置多大，是一件比较困难的事。
所以我们采用`增量快照`
制作一次全局快照之后，后续将修改的值，补写入全局快照即可。
但是我们单独记录的话， 修改的数据是身份庞大的，所以我们可以采用 AOF 和 RDB 结合的方法来搞定。使用AOF 来记录这块修改的内容。

* AOF
	- 以日志的形式来记录每个写操作（增量保存），将 Redis 执行过的所有写指令记录下 来(读操作不记录)， 只许追加文件但不可以改写文件
	- redis默认不开启，RDB和AOF同时开启，使用AOF
	- AOF的重写
	- **优势**
		- 备份机制更稳健，丢失数据概率更低
		- 可读的日志文本，通过操作 AOF 稳健，可以处理误操作
	- **劣势**
		- 比起 RDB 占用更多的磁盘空间
		- 恢复备份速度要慢
		- 每次读写都同步的话，有一定的性能压力
		- 存在个别 Bug，造成恢复不能
    - AOF三种写入磁盘时机
        - Always：同步写回，可靠性高，数据基本不丢失，每条指令都要落盘，性能差
        - Everysec：每秒写回，性能适中，丢失一秒内数据
        - No：操作系统控制的写回，性能好，丢失数据较多

<br>

### **AOF重写**
---

AOF重写的含义是将多条语句合并成一条，AOF写入是以追加的形式来的，重写就是保证其最新状态。
AOF的重写过程是由子线程来完成的，另外重写过程是这样的，子线程会拷贝主线程的内存，然后进行重写，这时如果有写操作继续执行的话，则放入缓冲区内，会同时放入重写缓冲区和写入缓冲区。
这时我们又有问题了，为什么不让父子进程同时写一个文件，因为这样会产生竞争，然后我们处理竞争又会影响速度。

推荐阅读：https://www.cnblogs.com/xuanyuan/p/13689484.html

<br>

### **Redis主从复制坑**
---

`主从数据不一致`
用户从从库读到的数据和主库中的不一致，因为我们的写操作是落在主库上的，先操作主库，然后再同步到从库，所以有可能存在延迟的情况。

我们可以这样解决
- 保证网络链接顺畅
- 设定一个监视器，然后通过监视器来监控复制进度，当复制进度大于阈值时，则不让其从从库访问

`读取过期数据`
因为当有数据过期时，如果是在主库读取到，则会执行删除策略，然后同步到从库，但是如果在从库读到过期键时，则不会删除，3.2之前会返回原来的值，3.2之后会返回空值。

`不合理配置`

<br>

### **Redis哨兵模式**
---

`哨兵模型算是主从复制模型的拓展，我们假设有四个节点，一主三从，当某个主节点挂掉之后，某个从节点顶替主节点。`
我们可以通过哨兵节点来执行这个操作，我们的哨兵节点用来监控主节点，当发现主节点挂掉之后，选取某个从节点来替代主节点，

但是如果某天哨兵节点挂了之后，我们整个监控系统也就完蛋了，所以我们可以搭建哨兵集群，这样整个哨兵集群挂掉的概率就很小了，然后当其中一个哨兵判断主节点挂掉之后，询问其他节点该主节点是否挂掉，如果超过一定值的哨兵节点判断挂掉之后，则认定该节点已经挂掉。

https://zhuanlan.zhihu.com/p/65504905

https://www.cnblogs.com/flashsun/p/14692643.html

<br>

### **Redis集群**
---

Redis集群是Redis 提供的分布式数据库方案，集群通过分片的来进行数据共享，并提供复制和故障转移功能。

* 槽指派 
Redis 集群通过分片的方式来保存数据库中的键值对，如果`有槽没有得到处理，那么集群将处于下线状态。`
集群中会通过slots数组进行来判断节点是否处理槽i,节点之间会告知其他节点自己负责什么槽。
在集群中执行命令
    - 如果键所在的槽并正好指派给了当前节点，那么节点立刻执行该命令
    - 如果键所在的槽没有指派给当前节点，那么节点会像客户端发送一个`MOVEN错误`，指引客户端转向至正确节点。

Redis共有 16384个哈希槽，每个key通过CRC16的校验和对16383（含有0）做与运算，来计算key在哪个槽。

* ASK错误
这个错误多发生于重新分片的过程中，我们将某节点的槽迁移到另一节点时，此时客户端传来命令，如果没有在对应的节点内查询到该槽中值，则说明已经发生了迁移，此时则返回 ASK 错误，然后开始去目标节点进行查询。

* Moven错误
这是正常请求错误，告知该数据不在该服务器的槽里。

* 故障检测
每隔一段时间，主节点之间会发送ping信息，如果没有一定时间内，得到回应，那么则被认为是疑似下线，当半数节点认为其疑似下线时，则认定其为已下线。

* 故障转移步骤
    - 复制下线主节点的所有从节点里面，会有一个节点被选中。
    - 被选中的节点会执行SLAVEOF no one 命令，成为新的主节点，
    - 将下线节点的所有槽指派下线，然后指向新的主节点。
    - 向其他节点发送ping信息，告知别人自己变成了主节点。

<br>

### **Redis分布式**
---

* Redis可以做消息队列吗？
消息队列需要有三种特性
- 有序性
- 重复消息处理
- 消息可靠性

我们使用List 则可以做到上面三条，有序性，重复消息（设置id），然后通过某些关键字实现可靠性（RPOPLPUSH）
基于 Streams 的消息队列解决方案
这个是Redis 专门为消息队列设置的数据类型
可以保证插入有序，并生成唯一id
会使用内部队列来保证可靠性。

* 并发访问
主要使用两种方法实现并发，`加锁` 和 `原子操作`
加锁缺点：会降低性能，另一个就是需要加分布式锁，加分布式锁会比较困难。
原子操作主要有两种方法
1.将多条操作合并为一个
比如我们修改库存的情况，获取值-减库存-存值，这就是三个操作，我们可以使用Redis 自带的关键字来使其变为原子操作
INCR/DECR增值和减值
2.使用lua 脚本，使其保证原子性

使用lua 脚本，将减库存的三个操作进行合并，其实保持原子性

* 分布式锁

**单个节点上的锁** 

分布式锁的实现需要两个条件
    - 保证加锁和解锁的原子性
    - 在共享存储上设置锁变量，必须保证锁变量的可靠性

实现分布式锁的方法
使用setnx 函数，完成分布式锁
解决方法，给每个线程设置一个id，解析还需系铃人
给锁的设定设置一个有效时间，到期未解锁，则进行，主动释放。注意上诉操作要保证原子性

**多个节点的锁** 

Redlock 算法的基本思路，是让客户端和多个独立的 Redis 实例依次请求加锁，如果客户端能够和半数以上的实例成功地完成加锁操作，那么我们就认为，客户端成功地获得分布式锁了，否则加锁失败。

缺点是锁比较重，降低业务效率。

http://zhangtielei.com/posts/blog-redlock-reasoning.html

<br>

### **Redis事务**
---

* 原子性
    - 命令入队时就报错，会放弃事务执行，保证原子性；命令入队时没报错，
    - 实际执行时报错，不保证原子性；
    - EXEC 命令执行时实例故障，如果开启了 AOF 日志，可以保证原子性。
* 隔离性
    - 如果开启了WATCH 机制则没有被破坏，因为其会监控键值对的改变。保证一致性
* 一致性
    - 在事务开始之前和事务结束以后，数据库的完整性没有被破坏。这表示写入的资料必须完全符合所有的预设约束、触发器、级联回滚等
* 持久性
    - 不保证持久性

<br>

### **Redis脑裂**
---

数据丢失的问题

脑裂：`多个主服务器，然后客户端，不知道该写入那个主服务器。则出现了多个客户端写入多个主服务器的情况。`
出现原因：主库假失败
脑裂为什么会发生数据丢失？
- 主库中的数据，未同步到从库，然后此时主库崩溃，则就出现了数据丢失的情况。
- 主服务器下线之后，有可能从库依旧和原来的主库进行交互，这样会导致新数据，放在不同的主库上。

因为我们此时产生脑裂，然后此时有两个主机，新写的数据会写入两个主机，然后造成两个主机都会保存数据，另外当切换新的主机的时候，原来的主机会清理掉所有数据，然后执行新主机发来的RDB文件，进而出现了数据丢失的情况。

如何防止脑裂，通过配置从库和主库发送ACK消息的延迟时间来解决。

<br>

### **乐观锁和悲观锁**
---

* 悲观锁每次在拿数据的时候都会上锁，这样别人想拿这个数据就会 block 直到它 拿到锁。传统的关系型数据库里边就用到了很多这种锁机制，比如行锁，表锁等，读 锁，写锁等，都是在做操作之前先上锁。
* 乐观锁(Optimistic Lock)每次去拿数据的时候都认为别人 不会修改，所以不会上锁，但是在更新的时候会判断一下在此期间别人有没有去更新 这个数据，可以使用版本号等机制。乐观锁适用于多读的应用类型，这样可以提高吞 吐量。Redis 就是利用这种 check-and-set 机制实现事务的
* 在执行 multi 之前，先执行 watch key1 [key2],可以监视一个(或多个) key ，如果在事务 执行之前这个(或这些) key 被其他命令所改动，那么事务将被打断。

<br>

## **细节问题**
---

### **Redis大Key**
---

大 key 除了会影响持久化之外，还会有以下的影响。
* 客户端超时阻塞。由于 Redis 执行命令是单线程处理，然后在操作大 key 时会比较耗时，那么就会阻塞 Redis，从客户端这一视角看，就是很久很久都没有响应。
* 引发网络阻塞。每次获取大 key 产生的网络流量较大，如果一个 key 的大小是 1 MB，每秒访问量为 1000，那么每秒会产生 1000MB 的流量，这对于普通千兆网卡的服务器来说是灾难性的。
* 阻塞工作线程。如果使用 del 删除大 key 时，会阻塞工作线程，这样就没办法处理后续的命令。
* 内存分布不均。集群模型在 slot 分片均匀情况下，会出现数据和查询倾斜情况，部分有大 key 的 Redis 节点占用内存多，QPS 也会比较大。

最好在设计阶段，就把大 key 拆分成一个一个小 key。或者，定时检查 Redis 是否存在大 key ，如果该大 key 是可以删除的，不要使用 DEL 命令删除，因为该命令删除过程会阻塞主线程，而是用 unlink 命令（Redis 4.0+）删除大 key，因为该命令的删除过程是异步的，不会阻塞主线程。 

<br>

### **Redis和MemCache的区别**
---

* 类型
    - Redis是一个开源的内存数据结构存储系统，用作数据库，缓存和消息代理
    - Memcached是一个免费的开源高性能分布式内存对象，通过减少负载来加速动态web应用程序
* 数据结构
    - Redis支持字符串，散列表，列表，集合，有序集，哈希表
    - Memcached支持字符串和整数
* 执行速度
    - Memcached的读写速度慢于Redis
* Value值
    - Redis最大512M
    - Memcache最大只能1M

https://blog.csdn.net/guoguo527/article/details/108818556

<br>