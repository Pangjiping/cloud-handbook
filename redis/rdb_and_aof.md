<p>redis提供了两种不同的持久化策略：RDB and AOF</p>
<p>&nbsp;</p>
<h1>1. RDB</h1>
<h2>1.1 什么是RDB</h2>
<p>RDB全称Redis DataBase，是在指定时间间隔内将内存的数据集快照写到磁盘，也就是snapshot快照，它恢复时是将快照文件直接读到内存里</p>
<p>&nbsp;</p>
<h2>1.2 备份是如何进行的</h2>
<div>redis&nbsp;会单独创建（fork）一个子进程来进行持久化，会先将数据写入到 一个临时文件中，待持久化过程都结束了，再用这个临时文件替换上次持久化好的文件。 整个过程中，主进程是不进行任何IO&nbsp;操作的，这就确保了极高的性能 如果需要进行大规模数据的恢复，且对于数据恢复的完整性不是非常敏感，那&nbsp;RDB&nbsp;方式要比&nbsp;AOF&nbsp;方式更加的高效。RDB&nbsp;的缺点是最后一次持久化后的数据可能丢失。</div>
<div>&nbsp;</div>
<div>fork的作用是复制一个与当前进程一样的进程。新的进程所有数据数值都和原进程一样，但是是一个全新的进程，并作为原进程的子进程</div>
<div>在linux操作系统中，fork()会产生一个和父进程完全相同的子进程，但子进程在此后多会exec系统调用，出于效率考虑，linux中引入了&ldquo;写时复制技术&rdquo;</div>
<div>一般情况下父进程和子进程会共用一段物理内存，只有进程空间的各段的内容要发生变化时，才会将父进程的内容复制给子进程一份</div>
<div>&nbsp;</div>
<h2>1.3 持久化流程</h2>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319154336662-692236304.png" alt="" width="492" height="305" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h2>1.4 优缺点</h2>
<p>优点：</p>
<ul>
<li>适合大规模数据恢复</li>
<li>对数据完整性和一致性要求不高使用</li>
<li>节省磁盘空间</li>
<li>恢复速度快</li>
</ul>
<p>缺点：</p>
<ul>
<li>fork时，内存中的数据被克隆了一份，大致两倍的膨胀需要考虑</li>
<li>
<div>虽然&nbsp;Redis&nbsp;在&nbsp;fork&nbsp;时使用了写时拷贝技术,但是如果数据庞大时还是比较消耗性能</div>
</li>
<li>
<div>在备份周期在一定间隔时间做一次备份，所以如果&nbsp;Redis&nbsp;意外&nbsp;down&nbsp;掉的话，就会丢失最后一次快照后的所有修改</div>
</li>
</ul>
<p>&nbsp;</p>
<h1>2. AOF</h1>
<h2>2.1 什么是AOF</h2>
<p>AOF是以日志的形式来记录每个写操作（增量保存），将redis执行过的所有写指令记录下来，只允许追加文件但不可以改写文件，redis重启之后会读取该文件重新构建数据</p>
<p>redis重启之后就是根据日志文件的内容将写指令从头到尾执行一次以完成数据恢复的过程</p>
<p>&nbsp;</p>
<h2>2.2 AOF持久化流程</h2>
<ul>
<li>客户端的请求写命令会被append追加到AOF缓冲区内</li>
<li>AOF缓冲区根据AOF持久化策略（always/everysec/no）将操作同步到磁盘的AOF文件中</li>
<li>AOF文件大小超过重写策略或者手动重写时，会对AOF文件rewrite，压缩AOF文件容量</li>
<li>redis服务重启时，会重新load加载AOF文件中的写操作以达到数据恢复的目的</li>
</ul>
<p>&nbsp;</p>
<h2>2.3 AOF同步频率设置</h2>
<ul>
<li>always：始终同步，每次redis的写入都会被立刻记入日志，性能较差但数据完整性好</li>
<li>everysec：每秒同步，每秒记录一次日志，如果宕机，本秒数据可能丢失</li>
<li>appendfsync no：redis不主动同步，把同步时机交给操作系统</li>
</ul>
<p>&nbsp;</p>
<h2>2.4 rewrite压缩</h2>
<div>AOF&nbsp;采用文件追加方式，文件会越来越大为避免出现此种情况，新增了重写机制，当AOF文件的大小超过所设定的阈值时，redis就会启动AOF文件的内容压缩， 只保留可以恢复数据的最小指令集。可以使用命令&nbsp;bgrewriteaof</div>
<div>&nbsp;</div>
<div>
<div>AOF&nbsp;文件持续增长而过大时，会&nbsp;fork&nbsp;出一条新进程来将文件重写（也是先写临时文件最后再&nbsp;rename）</div>
<div>redis4.0&nbsp;版本后的重写，是指上就是把&nbsp;rdb&nbsp;的快照，以二级制的形式附在新的&nbsp;aof&nbsp;头部，作为已有的历史数据，替换掉原来的流水账操作</div>
<div>&nbsp;</div>
<div>no-appendfsync-on-rewrite：</div>
<div>
<ul>
<li>no-appendfsync-on-rewrite = yes：不写入AOF文件，只写入缓存，用户请求不会阻塞，但是在这段时间如果宕机会丢失这段时间的内存。数据完整性低，但性能高</li>
<li>no-appendfsync-on-rewrite = no：还是会把数据刷到磁盘里，但是遇到重写操作，可能会发生阻塞。数据完整性高，但性能降低</li>
</ul>
<p>&nbsp;</p>
<h3>2.4.1 重写的触发机制</h3>
<p>redis会记录上一次重写时的AOF大小，默认配置是AOF文件大小是上次rewrite后大小的一倍且文件大于64M时触发</p>
<p>重写虽然可以节约大量磁盘空间，减少恢复时间。但是每次重写还是有一定的负担，因此设定redis要满足一定的条件才可以触发重写：</p>
<ul>
<li>auto-aof-rewrite-percentage：设置重写的基准值，文件达到100%时开始重写</li>
<li>auto-aof-rewrite-min-size：设置重写的基准值，最小文件64MB，达到这个值开始重写</li>
</ul>
<p>如果redis的AOF当前大小 &gt;= base_size + base_size * auto-aof-rewrite-percentage且当前大小 &gt;= 64MB，redis会对AOF进行重写</p>
<p>&nbsp;</p>
<h3>2.4.2 重写流程</h3>
<ol>
<li>bgrewriteaof触发，判断是否当前有bgsave或者bgrewriteaof在运行，如果有，等待该命令结束后再继续执行</li>
<li>主进程fork出子进程执行重写操作，保证主进程不会阻塞</li>
<li>子进程遍历redis内存中数据到临时文件，客户端的写请求同时写入aof_buf缓冲区和aof_rewrite_buf缓冲区保证原AOF文件完整性以及新的AOF文件生成期间的新的数据修改动作不会丢失</li>
<li>子进程写完新的AOF后，向主进程发信号，父进程更新统计信息</li>
<li>主进程把aof_rewrite_buf中的数据写入到新的AOF文件中</li>
<li>使用新的AOF文件覆盖原来的AOF文件，完成AOF重写</li>
</ol></div>
</div>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220323123541270-40561353.png" alt="" width="544" height="499" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<h2>2.5 AOF特点</h2>
<p>优势：</p>
<ul>
<li>备份机制更加稳健，丢失数据概率更低</li>
<li>可读的日志文本，通过操作AOF文件，可以处理误操作</li>
</ul>
<p>劣势：</p>
<ul>
<li>比起RDB占用更多磁盘空间</li>
<li>恢复备份速度要慢</li>
<li>每次读写都同步的话，有一定的性能压力</li>
<li>存在个别bug，不能修复</li>
</ul>
<p>&nbsp;</p>
<h1>3. 总结</h1>
<ul>
<li>RDB持久化方式能够在指定的时间间隔内对数据进行快照存储</li>
<li>
<div>AOF&nbsp;持久化方式记录每次对服务器写的操作，当服务器重启的时候会重新执行这些命令来恢复原始的数据，AOF&nbsp;命令以&nbsp;redis&nbsp;协议追加保存每次写的操作到文件末尾</div>
</li>
<li>redis还能对AOF进行重写，让文件不至于过大</li>
<li>如果你只希望redis做简单的缓存，只在服务器运行的时候存在，可以不做任何持久化操作</li>
<li>建议同时开启两种持久化方式</li>
<li>
<div>在同时开启的情况下，当&nbsp;redis&nbsp;重启的时候会优先载入&nbsp;AOF&nbsp;文件来恢复原始的数据,，因为在通常情况下&nbsp;AOF&nbsp;文件保存的数据集要比&nbsp;RDB&nbsp;文件保存的数据集要完整</div>
</li>
<li>建议不要只使用AOF，RDB&nbsp;更适合用于备份数据库</li>
</ul>
<p>&nbsp;</p>