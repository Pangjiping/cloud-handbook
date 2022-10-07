<h1>1. 状态机</h1>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220403150204416-540880912.png" alt="" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>从中我们可以得到几个我们需要实现的过程</p>
<ol>
<li>初始化所有节点为follower</li>
<li>需要一个选举超时定时器，当定时器超时时，一个follower状态转为candidate</li>
<li>candidate向其他节点请求投票，得到半数以上票数成为leader</li>
<li>candidate发现新的leader或者自己的term不够大时，转为follower</li>
<li>leader在复制日志或者传递心跳的过程中，发现更新的term，会转为follower</li>
</ol>
<p>&nbsp;</p>
<h1>2. 通用数据结构</h1>
<p>不论是一个节点位于哪种形态，都必须具备这些数据结构，其中一些是该节点独有的信息，而更多是关于集群的日志同步相关的</p>
<table style="height: 254px; width: 720px;" border="0" align="center">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>currentTerm</td>
<td>服务器当前已知最新的term，初始化为0，单调增加</td>
</tr>
<tr>
<td>voteFor</td>
<td>当前任期内收到选票的候选人id，如果不投票则为-1</td>
</tr>
<tr>
<td>NodeID</td>
<td>当前节点在集群中的ID，全局唯一</td>
</tr>
<tr>
<td>[]log</td>
<td>日志条目，每个条目包含了用于状态机的命令，以及领导者接收到该条目的term、index信息</td>
</tr>
<tr>
<td>commitIndex</td>
<td>已知已提交的最高的日志条目的索引（提交到大多数节点），单调递增</td>
</tr>
<tr>
<td>lastApplied</td>
<td>已经被应用到状态机的最高的日志条目的索引，单调递增</td>
</tr>
</tbody>
</table>
<p>其实 commitIndex 和 lastApplied 可以看做是 []log 数组中的两个指针，表明了有多少日志被集群提交了，有多少已经被应用到状态机了</p>
<p>其实在这里可以发现，已经应用到状态机的日志是不必继续保存的，后面会有一个快照机制，既可以压缩数据又可以迅速向新节点同步数据</p>
<p>我们可以简单梳理一下 []log 的结构：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220403152851823-380009581.png" alt="" width="764" height="276" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>观察 []log 的结构，我们可以发现一个日志所包含的基础字段，分别是 command、term、index</p>
<p>term就是同步这条日志的 leader 的 term ，index是一个全局单调递增的数字，用于和 term 标识唯一的 leader，并配合 lastApplied 和 commitIndex 使用</p>
<p>那么 lastApplied和commitIndex 是什么关系呢？</p>
<p>lastAppiled &lt;= commitIndex，二者中间日志就是已经提交到集群，但还没有应用到状态机的</p>
<p>这里就会有一个关于更新lastApplied的问题，当 lastApplied &lt; commitIndex 时，lastApplied +1，并把 log[lastApplied] 应用到状态机</p>
<p>&nbsp;</p>
<p>以上的这些数据基本都记录的是单机信息，raft 中最重要的日志同步，也就是 leader 向 follower 同步日志时需要怎么做呢？</p>
<p>其实每个 leader，或者说每个节点，因为每个节点都有可能成为 leader，都会存在两个数组，用于向 follower 同步日志</p>
<table style="height: 136px; width: 778px;" border="0">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>[]nextIndex</td>
<td>对于每一台服务器，发送到该服务器的下一个日志条目的索引（初始值为领导者最后的日志条目索引+1）</td>
</tr>
<tr>
<td>[]matchIndex</td>
<td>对于每一台服务器，已知的已经复制到该服务器的最高日志条目的索引（初始值为0，单调递增）</td>
</tr>
</tbody>
</table>
<p>其实简单来说就是：对于每一个follower，leader应该知道它要发给这个节点哪些日志</p>
<p>&nbsp;</p>
<h1>3. RPC</h1>
<p>最简单的 raft 算法实现需要两个RPC：日志追加/心跳RPC和选举投票RPC</p>
<p>其中日志追加RPC是由 leader 发送给 follower，选举投票RPC是由 candidate 发送给 candidate 和 follower</p>
<p>&nbsp;</p>
<h2>3.1 选举投票RPC</h2>
<p>在选举定时器超时后，follower 会转为 candidate，然后开启选举投票RPC</p>
<p>这个RPC请求的关键是让其他节点给自己投票，那么需要的请求参数就必须要表明该 candidate有成为一个 leader 的资格</p>
<p>发起投票请求的简单逻辑如下：</p>
<ol>
<li>选举定时器超时，follower转为candidate</li>
<li>新增当前自己的term currentTerm+=1</li>
<li>给自己的投票</li>
<li>重置选举超时定时器</li>
<li>发送投票请求RPC</li>
<li>如果收到了大多数服务器的选票，则成为新的 leader</li>
<li>如果收到了返回信息中发现更大了 term 或者直接收到 leader 的心跳或者日志RPC，则转为 follower</li>
<li>如果选举过程超时，再次发起一轮选举</li>
</ol>
<p>candidate 的请求参数主要包括了：</p>
<table style="height: 170px; width: 666px;" border="0">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>term</td>
<td>candidate的任期号</td>
</tr>
<tr>
<td>candidateID</td>
<td>candidate的ID</td>
</tr>
<tr>
<td>lastLogIndex</td>
<td>候选人的最新日志条目的索引值</td>
</tr>
<tr>
<td>lastLogTerm</td>
<td>候选人最新日志条目的任期号</td>
</tr>
</tbody>
</table>
<p>在其他节点收到投票请求后，主要会做一下term和index的校验：</p>
<ol>
<li>检查自己的 voteFor 是否等于-1，如果是表示已经投过票了，拒绝投票请求</li>
<li>检查 term 是否比自己的 term 新，如果不是表示 candidate 没有资格成为新的 leader，因为集群中已经存在比它数据更新的节点了</li>
<li>检查lastLogTerm，如果自己最新日志的 term 比candidate 的大，说明自己的日志更新，拒绝投票</li>
<li>检查lastLogIndex，在lastLogTerm相等时检查，如果自己的 index 比 candidate 的大，说明自己有更新的数据，拒接投票</li>
<li>所有的检查完毕，为 candidate 投上宝贵一票，同时更新自己的 term 为 candidate 的 term</li>
</ol>
<p>那么响应结构应该怎么设计？最简单的响应只需要两个返回值</p>
<table style="height: 119px; width: 631px;" border="0">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>term</td>
<td>当前任期号，以便于candidate发现更大的term从而转为follower，不要影响投票</td>
</tr>
<tr>
<td>voteGranted</td>
<td>是否为该candidate投票</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<h2>3.2 日志追加和心跳RPC</h2>
<p>日志追加和心跳可以何合为一个RPC是因为当日志中没有 command 就可以当成心跳来发送</p>
<p>leader 调用该RPC的时机主要有以下几个情况：</p>
<ul>
<li>客户端发起写请求</li>
<li>发送心跳</li>
<li>日志匹配失败</li>
</ul>
<p>&nbsp;</p>
<p>下面只简单说一下日志追加的过程</p>
<ol>
<li>一旦成为 leader，发送空的附加日志RPC给其他所有的服务器，在一定的空余时间之后不停地重复发送，阻止 follower 选举定时器超时</li>
<li>如果接收到客户端写请求，附加条目到本地日志中，在条目被应用到状态机后响应客户端</li>
<li>如果对一个跟随者，最后日志条目的索引大于或者等于 nextIndex，那么 leader 会发送从nextIndex开始的所有日志条目</li>
<li>如果成功，更新 follower 的nextIndex 和 matchIndex</li>
<li>如果因为日志不一致而失败，减小 nextIndex 重试</li>
<li>如果存在一个满足 N &gt; commitIndex 的 N，并且大多数的matchIndex[i] &gt;= N 成立，并且 log[N].term == currentTerm 成立，那么令 commitIndex等于这个N</li>
</ol>
<p>在请求参数中，需要包含以下几个部分：</p>
<table style="height: 238px; width: 646px;" border="0">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>term</td>
<td>当前leader的任期</td>
</tr>
<tr>
<td>leaderID</td>
<td>当前leader的id，主要用于跟随者对客户端进行重定向</td>
</tr>
<tr>
<td>prevLogIndex</td>
<td>紧邻新日志条目之前的那个条目的索引</td>
</tr>
<tr>
<td>prevLogTerm</td>
<td>紧邻新日志条目之前的那个条目的任期</td>
</tr>
<tr>
<td>[]entries</td>
<td>需要被保存的日志条目</td>
</tr>
<tr>
<td>leaderCommit</td>
<td>领导者的已知已提交的最高的日志条目的索引</td>
</tr>
</tbody>
</table>
<p>当 follower 收到日志追加或者心跳RPC时，会进行日志相关的操作</p>
<ol>
<li>如果 leader 的任期小于自己，那么返回自己的任期，并拒绝日志，之后就会开始新一轮的 leader 选举了</li>
<li>在 follower 日志中，如果能找到一个和&nbsp;prevLogIndex 和&nbsp;prevLogTerm 匹配的日志条目，则继续执行，否则拒绝日志，做冲突处理</li>
<li>如果一个已经存在的条目和新条目发生了冲突，则删除这个已经存在的条目以及它之后的所有条目</li>
<li>追加日志中尚未存在的任何新条目</li>
<li>如果 leader 的已知的已经提交的最高日志索引 leaderCommit 大于自己的，则 follower 把已知的已经提交的最高日志条目索引 commitIndex重置为 leaderCommit和最新日志条目索引的最小值</li>
</ol>
<p>所以在响应结构的设计中，主要包括了以下几部分：</p>
<table style="height: 170px; width: 650px;" border="0">
<tbody>
<tr>
<td>参数</td>
<td>解释</td>
</tr>
<tr>
<td>term&nbsp;</td>
<td>当前已知的最大任期</td>
</tr>
<tr>
<td>success</td>
<td>是否匹配index和term，并接受了日志</td>
</tr>
<tr>
<td>conflictLogIndex</td>
<td>和prevLogIndex不匹配的的log index</td>
</tr>
<tr>
<td>conflictLogTerm</td>
<td>和prevLogTerm不匹配的的log term</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p>至此通过两个RPC，就可以实现一个简单的raft协议</p>
<p>&nbsp;</p>
<h1>4. 工程优化</h1>
<p>（1）平均故障时间大于信息交换时间，系统没有一个稳定的领导者，集群不可用</p>
<p>　　解决：广播时间 &lt;&lt; 心跳超时时间 &lt;&lt; 平均故障时间</p>
<p>&nbsp;</p>
<p>（2）多个candidate同时发起选举RPC，选票被瓜分</p>
<p>　　解决：给选举定时器加上一个随机数，将超时时间分散</p>
<p>&nbsp;</p>
<p>（3）客户端如何知道哪个节点是 leader？</p>
<p>　　解决：客户端不需要知道leader节点，如果其写请求是发给了 follower，follower会重定向给leader节点</p>
<p>&nbsp;</p>
<p>（4）客户端从少数节点读取未同步的信息？</p>
<p>　　解决：每个客户端应该维护一个latestIndex值，每个节点在接受读请求时与自己的lastApplied值比较，如果这个值大于自己的lastApplied，那么就会拒绝这次读请求，客户端做重定向到一个可读的节点</p>
<p>&nbsp;</p>
<p>（5）快照</p>
<p>&nbsp;</p>
<p>（6）apply和commit异步处理，提高client的并发性</p>
<p>&nbsp;</p>
<p>参考：</p>
<p><a href="https://hardcore.feishu.cn/docs/doccnMRVFcMWn1zsEYBrbsDf8De#">Docs (feishu.cn)</a></p>
<p><a href="https://www.bilibili.com/video/BV1CK4y127Lj?spm_id_from=333.1007.top_right_bar_window_default_collection.content.click">Raft 分布式一致性(共识)算法 论文精读与ETCD源码分析_哔哩哔哩_bilibili</a></p>
<p><a href="https://zhuanlan.zhihu.com/p/27207160">Raft协议详解 - 知乎 (zhihu.com)</a></p>
<p><a href="https://www.cnblogs.com/xybaby/p/10124083.html">一文搞懂Raft算法 - xybaby - 博客园 (cnblogs.com)</a></p>