<p><span style="font-size: 14pt;"><strong>1. 哈希表的结构设计</strong></span></p>
<p>redis的哈希表结构如下：</p>

```c
typedef struct dictht{
  // 哈希表数组
  dictEntry **table;
  // 哈希表大小
  unsigned long size;
  // 哈希表大小掩码，用于计算索引
  unsigned long sizemask;
  // 该哈希表已有的节点数量
  unsigned long used;              
} dittht;
```
<p>&nbsp;</p>
<p>可以看到，哈希表是一个数组，数组的每个元素是一个指向哈希表节点的指针。</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319150711023-269543013.png" alt="" width="621" height="377" loading="lazy" /></p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>2. 哈希冲突</strong></span></p>
<p>哈希表实际上是一个数组，数组里每一个元素就是一个哈希桶</p>
<p>当一个键值对的键经过hash函数计算后得到哈希值，再将哈希值进行取模运算，得到的结果就是该key对应的数组元素位置，也就是第几个哈希桶</p>
<p>什么时候会产生哈希冲突呢？</p>
<p>举个例子，有一个可以存放8个哈希桶的哈希表。key1经过哈希函数计算后，再将哈希值%8进行取模运算，结果值为1，那么就对应哈希桶1，类似地，key9和jey10分别对应哈希桶1和6</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319151129322-814899962.png" alt="" width="677" height="461" loading="lazy" /></p>
<p>&nbsp;</p>
<p>当key1和key9分配到了相同的哈希桶中，就发生了哈希冲突</p>
<p>因此，当有两个以上数量的key被分配到了一个哈希桶中，此时称这些key发生了冲突</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>3. 链式哈希</strong></span></p>
<p>redis采用链式哈希来解决哈希冲突</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319151326910-666101958.png" alt="" width="648" height="343" loading="lazy" /></p>
<p>&nbsp;</p>
<div>链式哈希局限性也很明显，随着链表⻓度的增加，在查询这⼀位置上的数据的耗时就会增加，毕竟链表的查询的时间复杂度是&nbsp;O(n)</div>
<div>&nbsp;</div>
<p><span style="font-size: 14pt;"><strong>4. rehash</strong></span></p>
<p>在哈希表实际使用时，redis定义了一个dict结构体，这个结构体定义了两个哈希表</p>
<div class="cnblogs_code">
<pre>typedef <span style="color: #0000ff;">struct</span><span style="color: #000000;"> dict {
  ...
  </span><span style="color: #008000;">//</span><span style="color: #008000;"> 两个哈希表，交替使用，用于rehash</span>
  dictht ht[<span style="color: #800080;">2</span><span style="color: #000000;">];
  ...
} dict;</span></pre>
</div>
<p>&nbsp;</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319151700584-2044871878.png" alt="" width="653" height="336" loading="lazy" /></p>
<p>在正常服务请求阶段，插入的数据都会写到ht1中，此时ht2h还没有被分配空间。</p>
<p>随着数据的逐步增多，触发了rehash，这个过程分为三步：</p>
<ul>
<li>给ht2分配空间，一般会比ht1大2倍</li>
<li>将ht1的数据迁移到ht2中</li>
<li>迁移完成后，ht1将会被释放，并把ht2设置成ht1，然后ht2为下次rehash作准备</li>
</ul>
<p>这个过程看起来跟简单，但是数据迁移存在很大的问题，如果ht1的数量非常大，那么在迁移至ht2的时候，会因为大量数据的拷贝造成redis阻塞，无法服务其他请求。</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>5. 渐进式rehash</strong></span></p>
<div>为了避免&nbsp;rehash&nbsp;在数据迁移过程中，因拷⻉数据的耗时，影响 redis&nbsp;性能的情况，所以 redis&nbsp;采⽤了渐进式&nbsp;rehash，也就是将数据的迁移的⼯作不再是⼀次性迁移完成，⽽是分多次迁移。</div>
<div>
<ul>
<li>给ht2分配空间</li>
<li>
<div>在&nbsp;rehash&nbsp;进⾏期间，每次哈希表元素进⾏新增、删除、查找或者更新操作时，redis&nbsp;除了会执⾏对应的操作之外，还会顺序将ht1中索引位置上的所有&nbsp;key-value&nbsp;迁移到ht2上</div>
</li>
<li>
<div>随着处理客户端发起的哈希表操作请求数量越多，最终在某个时间，会把ht1的所有key-value&nbsp;迁移到ht2，从⽽完成&nbsp;rehash&nbsp;操作</div>
</li>
</ul>
</div>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>6. rehash触发条件</strong></span></p>
<div>rehash&nbsp;的触发条件跟负载因⼦（load factor）有关系</div>
<div>&nbsp;</div>
<div>负载因⼦可以通过下⾯这个公式计算</div>
<div>
<div>
<div class="cnblogs_code">
<pre>负载因子 = 哈希表已保存的节点数量/哈希表大小</pre>
</div>
<p>&nbsp;</p>
</div>
<div>&nbsp;</div>
<div>
<div>触发&nbsp;rehash&nbsp;操作的条件，主要有两个</div>
<div>
<ul>
<li>
<div>当负载因⼦⼤于等于&nbsp;1&nbsp;，并且 redis&nbsp;没有在执⾏&nbsp;bgsave&nbsp;命令或者&nbsp;bgrewiteaof&nbsp;命令，也就是没有</div>
<div>执⾏&nbsp;RDB&nbsp;快照或没有进⾏&nbsp;AOF&nbsp;重写的时候，就会进⾏&nbsp;rehash&nbsp;操作</div>
</li>
<li>
<div>当负载因⼦⼤于等于&nbsp;5&nbsp;时，此时说明哈希冲突⾮常严重了，不管有没有有在执⾏&nbsp;RDB&nbsp;快照或&nbsp;AOF</div>
<div>重写，都会强制进⾏&nbsp;rehash&nbsp;操作</div>
</li>
</ul>
</div>
</div>
</div>
<p>&nbsp;</p>