# **如何保证数据库和缓存的一致性**

根据CAP原理，分布式系统在可用性、一致性和分区容错性上无法兼得，通常由于分区容错无法避免，所以一致性和可用性难以同时成立。对于缓存系统来说，如何保证其数据一致性是一个在应用缓存的同时不得不解决的问题。

需要明确的是，缓存系统的数据一致性通常包括持久化层和缓存层的一致性、以及多级缓存之间的一致性，这里我们仅讨论前者。持久化层和缓存层的一致性问题也通常被称为双写一致性问题，“双写”意为数据既在数据库中保存一份，也在缓存中保存一份。对于一致性来说，包含强一致性和弱一致性，强一致性保证写入后立即可以读取，弱一致性则不保证立即可以读取写入后的值，而是尽可能的保证在经过一定时间后可以读取到，在弱一致性中应用最为广泛的模型则是最终一致性模型，即保证在一定时间之后写入和读取达到一致的状态。对于应用缓存的大部分场景来说，追求的则是最终一致性，少部分对数据一致性要求极高的场景则会追求强一致性。

<br>

## **1. 保证最终一致性的策略 (Cache Policy)**

为了达到最终一致性，针对不同的场景，业界逐步形成了下面这几种应用缓存的策略。

<br>

### **1.1 Cache-Aside**

Cache-Aside意为旁路缓存模式，是应用最为广泛的一种缓存策略。下面的图示展示了它的读写流程，来看看它是如何保证最终一致性的。在读请求中，首先请求缓存，若缓存命中（cache hit），则直接返回缓存中的数据；若缓存未命中（cache miss），则查询数据库并将查询结果更新至缓存，然后返回查询出的数据（demand-filled look-aside）。在写请求中，先更新数据库，再删除缓存（write-invalidate）。

![img](https://pic1.zhimg.com/80/v2-2d5c3224d4147cf9551423988b89e624_1440w.jpg)

**为什么删除缓存，而不是更新缓存？**

在Cache-Aside中，对于读请求的处理比较容易理解，但在写请求中，可能会有读者提出疑问，为什么要删除缓存，而不是更新缓存？站在符合直觉的角度来看，更新缓存是一个容易被理解的方案，但站在性能和安全的角度，更新缓存则可能会导致一些不好的后果。

首先是性能，当该缓存对应的结果需要消耗大量的计算过程才能得到时，比如需要访问多张数据库表并联合计算，那么在写操作中更新缓存的动作将会是一笔不小的开销。同时，当写操作较多时，可能也会存在刚更新的缓存还没有被读取到，又再次被更新的情况（这常被称为缓存扰动），显然，这样的更新是白白消耗机器性能的，会导致缓存利用率不高。而等到读请求未命中缓存时再去更新，也符合懒加载的思路，需要时再进行计算。删除缓存的操作不仅是幂等的，可以在发生异常时重试，而且写-删除和读-更新在语义上更加对称。

其次是安全，在并发场景下，在写请求中更新缓存可能会引发数据的不一致问题。参考下面的图示，若存在两个来自不同线程的写请求，首先来自线程1的写请求更新了数据库（step1），接着来自线程2的写请求再次更新了数据库（step3），但由于网络延迟等原因，线程1可能会晚于线程2更新缓存（step4晚于step3），那么这样便会导致最终写入数据库的结果是来自线程2的新值，写入缓存的结果是来自线程1的旧值，即缓存落后于数据库，此时再有读请求命中缓存（step5），读取到的便是旧值。

![img](https://pic1.zhimg.com/80/v2-03f398d1e1f45231717d6455559ce570_1440w.jpg)

**为什么先更新数据库，而不是先删除缓存？**

另外，有读者也会对更新数据库和删除缓存的时序产生疑问，那么为什么不先删除缓存，再更新数据库呢？在单线程下，这种方案看似具有一定合理性，这种合理性体现在删除缓存成功，但更新数据库失败的场景下，尽管缓存被删除了，下次读操作时，仍能将正确的数据写回缓存，相对于Cache-Aside中更新数据库成功，删除缓存失败的场景来说，先删除缓存的方案似乎更合理一些。那么，先删除缓存有什么问题呢？

问题仍然出现在并发场景下，首先来自线程1的写请求删除了缓存（step1），接着来自线程2的读请求由于缓存的删除导致缓存未命中，根据Cache-Aside模式，线程2继而查询数据库（step2），但由于写请求通常慢于读请求，线程1更新数据库的操作可能会晚于线程2查询数据库后更新缓存的操作（step4晚于step3），那么这样便会导致最终写入缓存的结果是来自线程2中查询到的旧值，而写入数据库的结果是来自线程1的新值，即缓存落后于数据库，此时再有读请求命中缓存（step5），读取到的便是旧值。

![img](https://pic2.zhimg.com/80/v2-0b0b66fc4ba97e0d54197832c89e9e41_1440w.jpg)

另外，先删除缓存，由于缓存中数据缺失，加剧数据库的请求压力，可能会增大缓存击穿出现的概率。

**如果选择先删除缓存，再更新数据库，那么如何解决一致性问题呢？**

为了避免“先删除缓存，再更新数据库”这一方案在读写并发时可能带来的缓存脏数据，业界又提出了延时双删的策略，即在更新数据库之后，延迟一段时间再次删除缓存，为了保证第二次删除缓存的时间点在读请求更新缓存之后，这个延迟时间的经验值通常应稍大于业务中读请求的耗时。延迟的实现可以在代码中sleep或采用延迟队列。显而易见的是，无论这个值如何预估，都很难和读请求的完成时间点准确衔接，这也是延时双删被诟病的主要原因。

![img](https://pic4.zhimg.com/80/v2-6234361c5618e37abf038bee9d0ad383_1440w.jpg)

**那么Cache-Aside存在数据不一致的可能吗？**

在Cache-Aside中，也存在数据不一致的可能性。在下面的读写并发场景下，首先来自线程1的读请求在未命中缓存的情况下查询数据库（step1），接着来自线程2的写请求更新数据库（step2），但由于一些极端原因，线程1中读请求的更新缓存操作晚于线程2中写请求的删除缓存的操作（step4晚于step3），那么这样便会导致最终写入缓存中的是来自线程1的旧值，而写入数据库中的是来自线程2的新值，即缓存落后于数据库，此时再有读请求命中缓存（step5），读取到的便是旧值。

这种场景的出现，不仅需要缓存失效且读写并发执行，而且还需要读请求查询数据库的执行早于写请求更新数据库，同时读请求的执行完成晚于写请求。足以见得，这种不一致场景产生的条件非常严格，在实际的生产中出现的可能性较小。

![img](https://pic1.zhimg.com/80/v2-f4d663ee2c435b72c22d72631c3ecdc0_1440w.jpg)

除此之外，在并发环境下，Cache-Aside中也存在读请求命中缓存的时间点在写请求更新数据库之后，删除缓存之前，这样也会导致读请求查询到的缓存落后于数据库的情况。

![img](https://pic4.zhimg.com/80/v2-16a7bc16934ed6c9a7889ce6373b68b7_1440w.jpg)

虽然在下一次读请求中，缓存会被更新，但如果业务层面对这种情况的容忍度较低，那么可以采用加锁在写请求中保证“更新数据库&删除缓存”的串行执行为原子性操作（同理也可对读请求中缓存的更新加锁）。加锁势必会导致吞吐量的下降，故采取加锁的方案应该对性能的损耗有所预期。

![img](https://pic2.zhimg.com/80/v2-d774644ed06e4d068fd29f6c1bad196d_1440w.jpg)

![img](https://pic1.zhimg.com/80/v2-ff36a03688f2464d3e20f8955ab4cd8c_1440w.jpg)

<br>

### **1.2 补偿机制**

我们在上面提到了，在Cache-Aside中可能存在更新数据库成功，但删除缓存失败的场景，如果发生这种情况，那么便会导致缓存中的数据落后于数据库，产生数据的不一致的问题。其实，不仅Cache-Aside存在这样的问题，在延时双删等策略中也存在这样的问题。针对可能出现的删除失败问题，目前业界主要有以下几种补偿机制。

#### **删除重试机制**

由于同步重试删除在性能上会影响吞吐量，所以常通过引入消息队列，将删除失败的缓存对应的key放入消息队列中，在对应的消费者中获取删除失败的key，异步重试删除。这种方法在实现上相对简单，但由于删除失败后的逻辑需要基于业务代码的trigger来触发，对业务代码具有一定入侵性。

![img](https://pic2.zhimg.com/80/v2-5f91dbeb4d37f876501a880984741d41_1440w.jpg)

#### **基于数据库日志（MySQL binlog）增量解析、订阅和消费**

鉴于上述方案对业务代码具有一定入侵性，所以需要一种更加优雅的解决方案，让缓存删除失败的补偿机制运行在背后，尽量少的耦合于业务代码。一个简单的思路是通过后台任务使用更新时间戳或者版本作为对比获取数据库的增量数据更新至缓存中，这种方式在小规模数据的场景可以起到一定作用，但其扩展性、稳定性都有所欠缺。

一个相对成熟的方案是基于MySQL数据库增量日志进行解析和消费，这里较为流行的是阿里巴巴开源的作为MySQL binlog增量获取和解析的组件canal（类似的开源组件还有Maxwell、Databus等）。canal sever模拟MySQL slave的交互协议，伪装为MySQL slave，向MySQL master发dump协议，MySQL master收到dump请求，开始推送binary log给slave（即canal sever），canal sever解析binary log对象（原始为byte流），可由canal client拉取进行消费，同时canal server也默认支持将变更记录投递到MQ系统中，主动推送给其他系统进行消费。在ack机制的加持下，不管是推送还是拉取，都可以有效的保证数据按照预期被消费。当前版本的canal支持的MQ有kafka或者RocketMQ。另外，canal依赖zookeeper作为分布式协调组件来实现HA，canal的HA分为两个部分：

* 为了减少对MySQL dump的请求压力，不同canal server上的instance要求同一时间只能有一个处于运行状态，其他的instance处于standby状态；
* 为了保证有序性，对于一个instance在同一时间只能由一个canal client进行get/ack等动作。

![img](https://pic2.zhimg.com/80/v2-f1a35beef71e121126e7b0106702bee5_1440w.jpg)

那么，针对缓存的删除操作便可以在canal client或consumer中编写相关业务代码来完成。这样，结合数据库日志增量解析消费的方案以及Cache-Aside模型，在读请求中未命中缓存时更新缓存（通常这里会涉及到复杂的业务逻辑），在写请求更新数据库后删除缓存，并基于日志增量解析来补偿数据库更新时可能的缓存删除失败问题，在绝大多数场景下，可以有效的保证缓存的最终一致性。

另外需要注意的是，还应该隔离事务与缓存，确保数据库入库后再进行缓存的删除操作。比如考虑到数据库的主从架构，主从同步及读从写主的场景下，可能会造成读取到从库的旧数据后便更新了缓存，导致缓存落后于数据库的问题，这就要求对缓存的删除应该确保在数据库操作完成之后。所以，基于binlog增量日志进行数据同步的方案，可以通过选择解析从节点的binlog，来避免主从同步下删除缓存过早的问题。

#### **数据传输服务DTS**

数据传输服务（Data Transmission Service，简称DTS）是云服务商提供的一种支持RDBMS（关系型数据库）、NoSQL、OLAP等多种数据源之间进行数据交互的数据流服务。DTS提供了包括数据迁移、数据订阅、数据同步等在内的多种数据传输能力，常用于不停服数据迁移、数据异地灾备、异地多活(单元化)、跨境数据同步、实时数据仓库、查询报表分流、缓存更新、异步消息通知等多种业务应用场景。

相对于上述基于canal等开源组件自建系统，DTS的优势体现在对多种数据源的支持、对多种数据传输方式的支持，避免了部署维护的人力成本。目前，各家云服务商的DTS服务已 针对云数据库，云缓存等产品进行了适配，解决了Binlog日志回收，主备切换等场景下的订阅高可用问题。在大规模的缓存数据一致性场景下，优先推荐使用DTS服务。

<br>

### **1.3 Read-Through**

Read-Through意为读穿透模式，它的流程和Cache-Aside类似，不同点在于Read-Through中多了一个访问控制层，读请求只和该访问控制层进行交互，而背后缓存命中与否的逻辑则由访问控制层与数据源进行交互，业务层的实现会更加简洁，并且对于缓存层及持久化层交互的封装程度更高，更易于移植。

![img](https://pic3.zhimg.com/80/v2-698537d181573d7dffdd12c55d8b948e_1440w.jpg)

<br>

### **1.4 Write-Through**

Write-Through意为直写模式，对于Write-Through直写模式来说，它也增加了访问控制层来提供更高程度的封装。不同于Cache-Aside的是，Write-Through直写模式在写请求更新数据库之后，并不会删除缓存，而是更新缓存。

![img](https://pic1.zhimg.com/80/v2-5c3b66c05d0ecfca09797c453cea3504_1440w.jpg)

这种方式的优势在于读请求过程简单，不需要查询数据库更新缓存等操作。但其劣势也非常明显，除了上面我们提到的更新数据库再更新缓存的弊端之外，这种方案还会造成更新效率低，并且两个写操作任何一次写失败都会造成数据不一致。

如果要使用这种方案，最好可以将这两个操作作为事务处理，可以同时失败或者同时成功，支持回滚，并且防止并发环境下的不一致。另外，为了防止缓存扰动的频发，也可以给缓存增加TTL来缓解。站在可行性的角度，不管是Write-Through模式还是Cache-Aside模式，理想状况下都可以通过分布式事务保证缓存层数据与持久化层数据的一致性，但在实际项目中，大多都对一致性的要求存在一些宽容度，所以在方案上往往有所折衷。

Write-Through直写模式适合写操作较多，并且对一致性要求较高的场景，在应用Write-Through模式时，也需要通过一定的补偿机制来解决它的问题。首先，在并发环境下，我们前面提到了先更新数据库，再更新缓存会导致缓存和数据库的不一致，那么先更新缓存，再更新数据库呢？这样的操作时序仍然会导致下面这样线程1先更新缓存，最后更新数据库的情况，即由于线程1和线程2的执行不确定性导致数据库和缓存的不一致。这种由于线程竞争导致的缓存不一致，可以通过分布式锁解决，保证对缓存和数据库的操作仅能由同一个线程完成。对于没有拿到锁的线程，一是通过锁的timeout时间进行控制，二是将请求暂存在消息队列中顺序消费。

![img](https://pic2.zhimg.com/80/v2-f65ba073710e0a7d536cbaf9918612d1_1440w.jpg)

在下面这种并发执行场景下，来自线程1的写请求更新了数据库，接着来自线程2的读请求命中缓存，接着线程1才更新缓存，这样便会导致线程2读取到的缓存落后于数据库。同理，先更新缓存后更新数据库在写请求和读请求并发时，也会出现类似的问题。面对这种场景，我们也可以加锁解决。

![img](https://pic1.zhimg.com/80/v2-cf0884d9cdcbb5a850f0eea4acc37888_1440w.jpg)

<br>

### **1.5 Write-Behind**

Write behind意为异步回写模式，它也具有类似Read-Through/Write-Through的访问控制层，不同的是，Write behind在处理写请求时，只更新缓存而不更新数据库，对于数据库的更新，则是通过批量异步更新的方式进行的，批量写入的时间点可以选在数据库负载较低的时间进行。

![img](https://pic1.zhimg.com/80/v2-a83d0519b786cefbc6b16a1da0db6320_1440w.jpg)

在Write-Behind模式下，写请求延迟较低，减轻了数据库的压力，具有较好的吞吐性。但数据库和缓存的一致性较弱，比如当更新的数据还未被写入数据库时，直接从数据库中查询数据是落后于缓存的。同时，缓存的负载较大，如果缓存宕机会导致数据丢失，所以需要做好缓存的高可用。显然，Write behind模式下适合大量写操作的场景，常用于电商秒杀场景中库存的扣减。

<br>

### **1.6 Write-Around**

如果一些非核心业务，对一致性的要求较弱，可以选择在cache aside读模式下增加一个缓存过期时间，在写请求中仅仅更新数据库，不做任何删除或更新缓存的操作，这样，缓存仅能通过过期时间失效。这种方案实现简单，但缓存中的数据和数据库数据一致性较差，往往会造成用户的体验较差，应慎重选择。

<br>

## **2. 总结**

在解决缓存一致性的过程中，有多种途径可以保证缓存的最终一致性，应该根据场景来设计合适的方案，读多写少的场景下，可以选择采用“Cache-Aside结合消费数据库日志做补偿”的方案，写多的场景下，可以选择采用“Write-Through结合分布式锁”的方案，写多的极端场景下，可以选择采用“Write-Behind”的方案。

<br>

## **Reference**
* https://zhuanlan.zhihu.com/p/457375259