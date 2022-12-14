# **MySQL**

## **基础问题**

---

### **MySQL架构**

---
mysql内部构造可以分为服务层和引擎层

* 服务层：连接器，查询缓存，分析器，优化器，执行器等，提供了MySQL 大部分的核心服务功能，以及内置函数，所有的跨存储引擎的功能都在这一层实现
* 存储引擎负责数据的存储和提取

![img](https://pic1.zhimg.com/80/v2-b29359b4bc5e849601c5df10a2a8e484_1440w.jpg)

<br>

### **SQL语句的执行过程**

---

* 进行链接，链接时进行验证，保证安全性，查看执行权限
* 查看缓存，缓存命中返回
* 连接器，分析器（这里查看语法是否有错误），优化器，执行器，搜索引擎

<br>

### **SQL语句关键字执行顺序**

---

```SQL
1. SELECT 
2. DISTINCT <select_list>
3. FROM <left_table>
4. <join_type> JOIN <right_table>
5. ON <join_condition>
6. WHERE <where_condition>
7. GROUP BY <group_by_list>
8. HAVING <having_condition>
9. ORDER BY <order_by_condition>
10.LIMIT <limit_number>
```

```SQL
FROM
<表名> # 笛卡尔积
ON
<筛选条件> # 对笛卡尔积的虚表进行筛选
JOIN <join, left join, right join...> 
<join表> # 指定join，用于添加数据到on之后的虚表中，例如left join会将左表的剩余数据添加到虚表中
WHERE
<where条件> # 对上述虚表进行筛选
GROUP BY
<分组条件> # 分组
<SUM()等聚合函数> # 用于having子句进行判断，在书写上这类聚合函数是写在having判断里面的
HAVING
<分组筛选> # 对分组后的结果进行聚合筛选
SELECT
<返回数据列表> # 返回的单列必须在group by子句中，聚合函数除外
DISTINCT
# 数据除重
ORDER BY
<排序条件> # 排序
LIMIT
<行数限制>
```

推荐阅读: <https://blog.csdn.net/u014044812/article/details/51004754>

<br>

### **Drop, Delete, Truncate**

---

* Drop 会安全删除表，并清空内存，不会触发触发器，这个命令不能回滚
* delete 用来删除表中的全部或者部分行，执行 delete 之后，可以删除或者撤销删除，内存不会被清空，会触动触发器，继续插入新值时，会继续之前的 id，可以是table 和 view
* truncate 不会触动触发器，会恢复内存，视图和索引不会产生影响，还会重置自增值。且只能针对表

<br>

### **MySQL索引类型**

---

* 哈希索引：可以直接通过关键字查询到数据，键值对，指定查询效率更高
* 数组索引：数组索引等值查询和范围查询效果较好，但是插入新数据的时候，需要做大量移动，降低性能
* B+树索引：InnoDB的数据都是存储在B+树上的。每一个索引在InnoDB里面对应一棵B+树

<br>

### **B+Tree和BTree**

---
因为B 中的每个节点都存储了key 和data，而B+树仅仅在叶子节点存储了key 和 data 也就是说B+树的数据都是存在叶子节点上的，这让我们使得非叶子节点可以存取更多的key，进而让B+树更加矮胖一些

因为索引树大部分情况下不能一次 I/O就读取到内存中的，树的深度越浅，查询的效率就越高一些，另外还有就是，B+树的叶子节点，是通过双向链表进行连接的，我们进行范围查询时效率更高，可以向前查找向后查找，另外B树的话，只能再次从根节点进行查询

![img](https://img-blog.csdn.net/20160202205105560)

**其他索引结构的缺点**

* 二叉搜索树: 当数据是单调递增或递减时，则会退化成链表
* AVL树: 因为维护二叉平衡树的开销比收益要大的多，我们作为索引的数据结构，更多的要求局部，而不是非常严格的平衡的红黑树。不过对于插入较少，查找较多的场景AVL的性能还是较高的。另外AVL树的每个节点只存储一个键值和数据
* 红黑树: 红黑树是一个弱平衡树，但是随着插入数据过多，查询数据时造成的I/O消耗也是巨大的，因为我们很多时候，一次查询并不能将所有数据全部存入内存中，深度过深的话，会加大I/O开销

参考链接: <https://www.cnblogs.com/tiancai/p/9024351.html>

<br>

### **索引失效**

---

* where语句为 % a 时的模糊查询（不走）
* 使用 a or b 进行查询时（a，b都有索引的定值查询时走，其余不走）索引合并
* in （走）not in （不走）
* is null 等字段（无记录，不走）
* ≠ <> 等字段（不走）

<br>

### **不需要索引**

---

* 数据量少的时候可以不需要加索引
* 更新比较频繁的数据
* 区分度较低的属性（性别）

<br>

### **主键索引和二级索引**

---

* 聚集索引又称为主键索引，非聚集索引又称为二级索引
* 主键索引每个表里只能有一个，二级索引可以有多个
* 另外主键索引的存的值为元组，也就是数据，二级索引存的值为主键，获取数据还需要进行一次回表操作

<br>

### **联合索引**

---
![img](https://pic2.zhimg.com/v2-fcde0ef783885b6b17999f39ca2808b5_r.jpg)

key为联合属性，value 为ID

**最左前缀**

当我们创建组合索引时，我们会将访问最频繁的字段放到最前面，比如（a,b,c），我们进行数据查询时，可以不完全使用索引的全部定义，只要满足左前缀就可使用索引查询。

创建这个索引就相当于创建了 a, ab, abc 三个索引。

**索引下推**

查询时，如果满足最左前缀，则可以利用最左前缀原则进行查询。

比如我们需要查找，名字姓张，年龄为 10 岁的孩子，如果我们此时创建了(名字,年龄)的联合索引，则可以查询到 名字和年龄对应的主键，然后再进行回表查询到数据。

我们如果对索引进行下推的话，则可以对联合索引查询到的值进行过滤，删除掉符合名字但是不符合年龄的数据。减少回表次数。

<br>

### **MySQL优化**

---

**建表优化**

* 尽量使用数字型字段，因为查询和链接时，只需比较一次，效率更快
* 尽量使用varchar少使用char，变长字段空间少，更省空间
* 对于区分度较低的索引，也就是有大量重复的索引，我们可以对其删除

**查询优化**

* 少使用select * 语句
* 尽量少使用模糊查询 %a
* 不使用 not in ，in，这样会导致走全表索引
* 不使用 a or b 方式进行查询，会使其不走索引
* 尽量少使用子查询（因为需要创建临时表，还需要删除临时表）

**索引优化**

* 不要创建太多索引，多使用组合索引
* 对经常 order by 的语句创建索引

<br>

### **explain**

---
| 列名            | 描述                                                       |
| --------------- | ---------------------------------------------------------- |
| `id`            | 在一个大的查询语句中每个`SELECT`关键字都对应一个唯一的`id` |
| `select_type`   | `SELECT`关键字对应的那个查询的类型                         |
| `table`         | 表名                                                       |
| `partitions`    | 匹配的分区信息                                             |
| `type`          | 针对单表的访问方法                                         |
| `possible_keys` | 可能用到的索引                                             |
| `key`           | 实际上使用的索引                                           |
| `key_len`       | 实际使用到的索引长度                                       |
| `ref`           | 当使用索引列等值查询时，与索引列进行等值匹配的对象信息     |
| `rows`          | 预估的需要读取的记录条数                                   |
| `filtered`      | 某个表经过搜索条件过滤后剩余记录条数的百分比               |
| `Extra`         | 一些额外的信息                                             |

id：一个select一个id，对于连接查询来说他们只有一个 select 但是因为需要使用两个表，所以会出现两行数据，但是是相同id。另外优化器会对子查询进行重写，将子查询变成连接查询，所以我们只需要看有几个id就可以判断是否进行了重写。

如果id 为null则是创建的临时表。

推荐阅读： <https://juejin.cn/post/6905232255937937415>

<br>

### **MySQL持久化**

---
**redolog**

* redolog是innoDB特有的技术
* WAL技术：WAL技术的全称是write-Ahead logging ,他的关键字，就是先写粉板，等不忙的时候再也账本。此时的粉板就是redolog，账本也就是磁盘
* InnoDB redolog的大小是固定大小的，比如一组可以为4个文件，每个1G，当redolog快要满的时候，则需要及性能存入磁盘
* 这个redolog 也是在磁盘里的，只不过其是顺寻I/O速度更快

**binlog**

* binlog是在server层日志，所有引擎都可以实现
* redolog是物理日志，记录在某个数据页上做了什么修改
* binlog是逻辑日志，比如某条记录的某个字段+1
* redolog是循环写的，binlog是可以追加写入
  
两阶段提交，是为了让两份日志之间逻辑一致，等两份日志，逻辑一致时，才进行提交

![img](https://img2020.cnblogs.com/blog/1460815/202101/1460815-20210126130746571-1886988411.png)

推荐阅读: <https://www.cnblogs.com/caoyier/p/14329755.html>

<br>

### **MySQL事务**

---

**ACID**

* 原子性：要做就做完，要么就不做
* 一致性：修改前后，不会破坏数据的完整性，无论转账成功是否，不会破坏两个人的账户总金额
* 持久性：修改完之后，永久有效
* 隔离性：多个事务并发操作时，互不干扰井水不犯河水

**事务隔离级别**

* 读未提交：其他事务未提交即可读
* 读提交：提交后即可读
* 可重复读：两次读的值一致
* 串行化

![img](https://gitee.com/cookchef/test/raw/master/img/image-20211012143745523.png)

**脏读、幻读、不可重复读**

* 事务A、B交替执行，事务A被事务B干扰到了，因为事务A读取到事务B未提交的数据，这就是脏读
* 在一个事务范围内，两个相同的查询，读取同一条记录，却返回了不同的数据，这就是不可重复读
* 事务A查询一个范围的结果集，另一个并发事务B往这个范围中插入/删除了数据，并静悄悄地提交，然后事务A再次查询相同的范围，两次读取得到的结果集不一样了，这就是幻读

<br>

### **MySQL如何保证原子性**

---
原子性主要是通过undolog来实现的，因为这个日志里面记录的操作的相反操作，比如insert ，则我们可以通过查询回滚日志，来进行撤销操作。这也就让我们可以回滚事务

* 当你delete一条数据的时候，就需要记录这条数据的信息，回滚的时候，insert这条旧数据
* 当你update一条数据的时候，就需要记录之前的旧值，回滚的时候，根据旧值执行update操作
* 当你insert一条数据的时候，就需要这条记录的主键，回滚的时候，根据主键执行delete操作

`undo log`记录了这些回滚需要的信息，当事务执行失败或调用了rollback，导致事务需要回滚，便可以利用undo log中的信息将数据回滚到修改之前的样子

<br>

### **MVCC基本概念**

---
MVCC：多版本并发控制，这样每条记录就能够生成一个版本链，每个事务可以查看不同的版本。

![img](https://gitee.com/cookchef/test/raw/master/img/image-20211012145209676.png)

**当前读和快照读**

* 当前读：当前读就是读和写之前，对其加锁，比如共享锁和排他锁，他们读到的是数据库的最新版本
* 快照读：就是在不加锁的select 语句里，但是此时的隔离级别不能是串行化调度，因为串行化调度会退化到当前读，快照读的出现就是为了实现并发控制，其实现就是基于MVCC，快照读读到的不一定是最新状态，有可能是历史状态

工作原理：事务在启动前会生成一个全库级别的快照，我们可能会想数据库的数据可是非常庞大的，全局数据快照是不是很夸张，数据表中的一行记录，其实可能有多个版本 (row)，每个版本有自己的 row trx_id

<br>

### **MVCC实现原理**

---
当某个数据被存入时，比如 id=1， name=XXX，此时不仅会存入这两个值，还会存入，两个隐藏字段，`trx_id`和`roll_pointer`。所以，InnoDB 可以通过，回滚日志来复原当前操作的反向操作

![img](https://gitee.com/cookchef/test/raw/master/img/image-20211012145337732.png)

另外需要注意的是，当某个插入型事务提交之后，对应的undolog则会被回收，因为没有人会再访问之前的数据了

当某个事务执行更新操作时，则会有下面这种情况

![img](https://gitee.com/cookchef/test/raw/master/img/image-20211012145404734.png)

另一个事务也执行更新操作时则会这样存储回滚日志

![img](https://gitee.com/cookchef/test/raw/master/img/image-20211012145443181.png)

修改型事务提交之后，不会被立刻删除，而是会追加，我们则可以根据undolog 访问之前的版本。好啦，版本的事到这我们就理解了，然后我们说一个Readview，这个就是用来判断哪个版本对哪个用户可见，哪个不可见的

**读提交(不可重复读)**

这里有四个规则

* creator_trx_id，当前事务ID
* m_ids，生成 readView 时还活跃的事务ID集合，也就是已经启动但是还未提交的事务ID列表
* min_trx_id，当前活跃ID之中的最小值。（最早开启的一个id)
* max_trx_id，生成 readView 时 InnoDB 将分配给下一个事务的 ID 的值（事务 ID 是递增分配的，越后面申请的事务ID越大）

对于可见版本的判断是从最新版本开始沿着版本链逐渐寻找老的版本，如果遇到符合条件的版本就返回

判断条件如下：

* 如果当前数据版本的 trx_id ==  creator_trx_id 说明修改这条数据的事务就是当前事务，所以可见。
* 如果当前数据版本的 trx_id  <  min_trx_id，说明修改这条数据的事务在当前事务生成 readView 的时候已提交，所以可见。
* 如果当前数据版本的 trx_id 在 m_ids 中，说明修改这条数据的事务此时还未提交，所以不可见。
* 如果当前数据版本的 trx_id >= max_trx_id，说明修改这条数据的事务在当前事务生成 readView 的时候还未启动，所以不可见(结合事务ID递增来看)。

**可重复读**

现在的隔离级别是可重复读。

可重复读和读已提交的 MVCC 判断版本的过程是一模一样的，唯一的差别在生成 readView 上。

上面的读已提交每次查询都会重新生成一个新的 readView ，而可重复读在第一次生成  readView 之后的所有查询都共用同一个 readView 。

也就是说可重复读只会在第一次 select 时候生成一个 readView ，所以一个事务里面不论有几次 select ，其实看到的都是同一个 readView 。

套用上面的情况，差别就在第二次执行`select name where id 1`，不会生成新的 readView，而是用之前的 readView，所以第二次查询时：

* m_ids 还是为 [5，6]，虽说事务 5 此时已经提交了，但是这个readView是在事务5提交之前生成的，所以当前还是认为这两个事务都未提交，为活跃的。
* 此时 min_trx_id，为 5。

所以在可重复级别下，两次查询得到的 name 都为 XX，所以叫可重复读。

推荐阅读: <https://zhuanlan.zhihu.com/p/383842414>

<br>

## **细节问题**

---

### **InnoDB和MyIsam**

---

* InnoDB 支持事务，MyIsam 不支持事务
* InnoDB 主键索引存的是数据，MyIsam存的是地址
* InnoDB 支持外键索引
* InnoDB 支持MVCC

<br>

### **MySQL经典报错信息**

---

* error 1062 - 字段值重复，入库失败
* error 1 - 用户权限不足
* error 1418 - 开启了bin-log，需要配置log_bin_trust_function_creators
* error 1005 - 创建表失败
* error 1006 - 创建数据库失败

更多错误: <https://developer.aliyun.com/article/557039>

<br>

### **MySQL主从**

---

* 在从库上采用mysqldump备份并记录主库binlog、Position点，需要加什么参数？ - `--dump-slave`
*

<br>

### **在列查询语句建立最优索引**

---

```sql
select * from test where a=1 and b=1；
select * from test where b=1；
select * from test where b=1 order by time desc；
```

索引: `idx_btime(b,time)`

<br>

### **索引长度**

---
MySQL InnoDB对于索引长度的限制为767字节，并且UTF8mb4字符集是4字节字符集，则默认索引最大长度为191字符，所以在varchar(255)或者char(255)类型字段上创建索引会失败

* 所有的索引字段，如果没有设置`NOT NULL`，则需要增加一个字节
* 定长字段，int占4字节，date占3字节，char(n)占n*4字节
* 对于变长字段varchar(n)，则有n*4+2个字节
* 不同的字符集，一个字符占用的字节数不同
* 索引长度char()、varchar()索引长度的计算公式:
`(Character Set: utf8mb4=4,utf8=3,gbk=2,latin1=1) * 列长度 + 1(允许null) + 2(变长列)`

<br>

### **两阶段提交**

---

两阶段提交就是把一个事务分成两个阶段来提交:

* 执行器想要更新记录A
* InnoDB将记录A加载到Buffer Pool
* 将记录A旧值写入undolog便于回滚
* 执行器更新内存中的数据（此时数据页为脏页）
* 【准备提交事务】执行器写redolog(**Prepare**)，这是第一阶段的提交
* 执行器写binlog
* 执行器(**Commit**)，这是第二阶段提交【事务结束】

![img](https://ask.qcloudimg.com/http-save/yehe-1337634/rhli8owssb.png?imageView2/2/w/1620)

**为什么需要两阶段提交？**

在mysql中，binlog是默认不开启的状态，也就是说如果你不需要binlog带来的特性（数据库备份、mysql主从）那根本不用让mysql写binlog，那么两阶段提交就失去了意义了

两阶段提交的主要目的是：为了保证redolog和binlog的数据的安全一致性。只有在这两个日志文件逻辑上高度一致了，才能放心的使用redolog帮你恢复到crash之前的状态，使用binlog实现数据备份、恢复、主从复制。而两节点提交的机制可以保证这两个日志的高度一致

**sync_binlog = 1**

`sync_binlog`这个参数控制binlog的落盘时机，这个参数设置为1时，表示当事务提交时会将binlog落盘。

而这个`事务提交时`时刻，就是**Prepare**时刻！

来模拟一个数据库crash的场景。假如现在要执行一条update操作，肯定是先写`undolog`用来回滚事务，然后update逻辑将Buffer Pool中的缓存页写成了脏页。当准备提交事务时，也就是**Prepare**时刻，会写`redolog`，并将其标记为prepare阶段，然后写binlog，并将binlog落盘。

然后发生意外，mysql crash

那么在重启mysql服务之后，这个脏页是会被回滚还是被提交？

答案是这个update逻辑会被recovery出来，然后提交

为什么会提交？

其实总的来讲，不论mysql在什么时刻crash，最终commit还是rollback完全取决于mysql能不能判断出binlog和redolog在逻辑上是否达成了一致。只要逻辑上达成了一致就可以commit，否则只能rollback

**那么如何判断`binlog`和`redolog`达成一致了呢？**

当mysql写完`redolog`并将它标记为**Prepare**状态时，会在`redolog`中记录一个`XID`，它是全剧唯一的事务标识符。当你设置`sync_binlog=1`时，做完了上面第一阶段写`redolog`之后，mysql就会写对应`binlog`并将其刷新到磁盘中。

`binlog`结束的位置也有一个`XID`。只要这个`XID`和`redolog`中记录的`XID`是一致的，mysql就会认为`binlog`和`redolog`逻辑上一致。就上面的场景来讲就会commit，而如果仅仅是`redolog`中记录了`XID`，而`binlog`中没有，mysql就会rollback

<br>

### **MySQL笔试题**

---

* <https://blog.csdn.net/sunfengye/article/details/88890951>
* <https://cloud.tencent.com/developer/article/1056350>
* <https://cloud.tencent.com/developer/article/1610942>
* <https://blog.csdn.net/h1025372645/article/details/90722166>
* <https://www.cnblogs.com/dannylinux/articles/8288790.html>

<br>
