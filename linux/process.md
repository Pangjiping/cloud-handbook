<p><span style="font-size: 14pt;"><strong>1. linux有哪些进程</strong></span></p>
<p>linux下的主要进程状态有：</p>
<ul>
<li>R(TASK_RUNNING) -- 可执行状态</li>
<li>S(TASK_INTERRUPTIBLE) &nbsp;-- 可中断的睡眠状态</li>
<li>D(TASK_UNINTERRUPTIBLE) -- 不可中断的睡眠状态</li>
<li>T(TASK_STOPPED or TASK_TRACED) -- 暂停状态或跟踪状态</li>
<li>Z(TASK_DEAD) -- 退出状态，也称僵尸状态</li>
</ul>
<p>&nbsp;</p>
<p><strong>2.1&nbsp;R(TASK_RUNNING) -- 可执行状态</strong></p>
<p>通过将进程的task_struct结构放到CPU的可执行队列中，使进程变成R态。只有处在该状态的进程才有可能被进程调度器选中在CPU上执行</p>
<p>&nbsp;</p>
<p><strong>2.2&nbsp;S(TASK_INTERRUPTIBLE) &nbsp;-- 可中断的睡眠状态</strong></p>
<p>当进程需要等待某件事的发生，比如socket连接等待对方输入时，进程的task_struct结构被放入相应事件的等待队列中。当事件被触发时，相应事件的等待队列中的某些进程就会被唤醒</p>
<p>&nbsp;</p>
<p><strong>2.3&nbsp;D(TASK_UNINTERRUPTIBLE) -- 不可中断的睡眠状态</strong></p>
<p>进程此时也是处于睡眠状态，但是不可以被kill掉。为什么要设置一种不可中断的睡眠状态呢？原来是为了保护内核状态下的某些流程不被打断</p>
<p>&nbsp;</p>
<p><strong>2.4&nbsp;T(TASK_STOPPED or TASK_TRACED) -- 暂停状态或跟踪状态</strong></p>
<div>
<div>TASK_STOPPED 和TASK_TRACED都表示进程被暂停下来，但不同的是TASK_STOPPED状态下，进程可以被SIGCONT信号唤醒，而TASK_TRACED下进程不能被该信号唤醒。TASK_TRACED状态通常发生在调试时，进程在断电处停下来，此时即被跟踪，只有当完成调试时，才能返回TASK_RUNNING状态</div>
<div>&nbsp;</div>
<div><strong>2.5&nbsp;Z(TASK_DEAD) -- 退出状态，也称僵尸状态</strong></div>
<div>
<div>在这个退出过程中，进程占有的所有资源将被回收，除了task_struct结构（以及少数资源）以外。于是进程就只剩下task_struct这么个空壳，故称为僵尸。如果父进程不退出，那么僵尸状态的子进程就一直存在</div>
<div>&nbsp;</div>
<div>&nbsp;</div>
</div>
</div>
<p><span style="font-size: 14pt;"><strong>2. linux进程管理指令</strong></span></p>
<p><strong>2.1 ps</strong></p>
<p>ps能列出系统中运行的进程，包括进程号、命令、CPU使用量、内存使用量等。下述选项可以得到更多有用的消息。</p>
<div class="cnblogs_code">
<pre><span style="color: #000000;">#列出所有运行中的进程
</span><span style="color: #0000ff;">ps</span> -<span style="color: #000000;">a 

# 列出xxx进程信息
</span><span style="color: #0000ff;">ps</span> -ef | <span style="color: #0000ff;">grep</span><span style="color: #000000;"> xxx

# 显示进程信息，包括无终端(x)和针对用户(u)的进程：如USER, PID, </span>%CPU, %<span style="color: #000000;">MEM
</span><span style="color: #0000ff;">ps</span> -aux</pre>
</div>
<p>&nbsp;</p>
<p><strong>2.2 pstree</strong></p>
<p>Linux中，每个进程都是由其父进程创建的。此命令以可视化的方式显示进程，通过进程的树状图来展示进程之间的关系</p>
<p>如果指定了pid，那么树的根是该pid，不指定pid=1</p>
<div class="cnblogs_code">
<pre>pstree</pre>
</div>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321172710762-372466139.png" alt="" width="522" height="351" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong>2.3 top</strong></p>
<p>top可以监视系统中不同的进程所使用的资源。它提供实时的系统状态信息，显示进程的数据包括了：</p>
<ul>
<li>PID</li>
<li>进程属主</li>
<li>优先级</li>
<li>%CPU</li>
<li>%MEM等</li>
</ul>
<div class="cnblogs_code">
<pre>top</pre>
</div>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321173207835-490336645.png" alt="" width="545" height="367" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong>2.4 htop</strong></p>
<p>htop和top很类似，但是htop是交互式的文本模式的进程查看器，它通过文字图形化地显示每一个进程的CPU和内存使用量、swap使用量。</p>
<p>使用上下光标选择进程，F7和F8改变优先级，F9杀死进程。</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321173654283-255947578.png" alt="" width="551" height="371" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong>2.5 nice</strong></p>
<p>nice可以设置和改变进程的优先级</p>
<p>默认情况下，进程以0优先级启动，进程优先级可以通过top显示的NI列查看</p>
<p>进程优先级从-20到19，值越低，优先级越高</p>
<div class="cnblogs_code">
<pre><span style="color: #0000ff;">nice</span> &lt;优先级&gt; &lt;进程名&gt; </pre>
</div>
<p>&nbsp;</p>
<p><strong>2.6 renice</strong></p>
<p>renice命令类似于nice命令</p>
<p>使用renice可以改变正在运行的进程优先级</p>
<p>注意，用户只能改变属于他们自己的进程的优先级</p>
<div class="cnblogs_code">
<pre><span style="color: #000000;"># 改变3806进程的优先级为4
</span><span style="color: #0000ff;">renice</span> -n <span style="color: #800080;">4</span> -p <span style="color: #800080;">3806</span><span style="color: #000000;">

# 用户为mint的所有进程优先级变为</span>-<span style="color: #800080;">3</span>
<span style="color: #0000ff;">renice</span> -<span style="color: #800080;">3</span> -u mint</pre>
</div>
<p>&nbsp;</p>
<p><strong>2.7 kill&nbsp;</strong></p>
<div class="cnblogs_code">
<pre><span style="color: #000000;"># 杀死某个进程
</span><span style="color: #0000ff;">kill</span> &lt;pid&gt;<span style="color: #000000;">

# 强制杀死某个进程
</span><span style="color: #0000ff;">kill</span> -<span style="color: #800080;">9</span> &lt;pid&gt;<span style="color: #000000;">

# 杀死拥有相同名字的进程
</span><span style="color: #0000ff;">killall</span> -<span style="color: #800080;">9</span><span style="color: #000000;"> 

# 使用进程名杀死进程
pkill </span>&lt;进程名&gt;</pre>
</div>
<p>&nbsp;</p>
<p><strong>2.8 ulimit</strong></p>
<p>该命令用于控制系统资源在shell和进程上的分配量。</p>
<p>可以管理重度使用和存在性能问题的系统，限制资源大小可以确保重要进程持续运行，该进程不会占用过多资源</p>
<div class="cnblogs_code">
<pre><span style="color: #000000;"># 显示当前用户关联的资源限制
ulimit </span>-<span style="color: #000000;">a

# </span>-<span style="color: #000000;">f: 最大文件尺寸大小
# </span>-<span style="color: #000000;">v: 最大虚拟内存大小（KB）
# </span>-<span style="color: #000000;">n: 增加最大文件描述符的数量
# </span>-<span style="color: #000000;">H:改变和报告硬限制
# </span>-s:改变和报告软限制</pre>
</div>
<p>&nbsp;</p>
<p><strong>2.9 w</strong></p>
<p>w提供当前登录用户及其正在执行的进程信息。</p>
<p>显示的信息头包含当前时间、系统运行时长、登录用户数、过去的1,5,15分钟内的负载均衡数</p>
<p>&nbsp;</p>
<p><strong>2.10 pgrep</strong></p>
<p>pgrep的意思是"进程号全局正则匹配输出"</p>
<p>该命令扫描当前运行进程，然后按照命令匹配条件列出匹配结果到标准输出。对于通过名字检索进程号是很有用</p>
<div class="cnblogs_code">
<pre># 显示用户为&lsquo;mint&rsquo;和进程名为&lsquo;<span style="color: #0000ff;">sh</span><span style="color: #000000;">&rsquo;的进程ID
pgrep </span>-u mint <span style="color: #0000ff;">sh</span></pre>
</div>
<p>&nbsp;</p>
<p><strong>2.11 fg, bg</strong></p>
<p>有时，命令需要很长的时间才能执行完成。对于这种情况，我们使用&lsquo;bg&rsquo;命令可以将任务放在后台执行，而用&lsquo;fg&rsquo;可以调到前台来使用</p>
<div class="cnblogs_code">
<pre># 使用&amp;<span style="color: #000000;">开启一个后台进程
</span><span style="color: #0000ff;">find</span> . -name *iso &gt; /tmp/res.txt &amp;<span style="color: #000000;">

# 查看所有后台进程
jobs

# 将后台程序调到前台执行
fg </span>&lt;pid&gt;</pre>
</div>
<p>&nbsp;</p>
<p><strong>2.12 ipcs</strong></p>
<p>ipcs命令报告进程间通信设施状态。（共享内存，信号量和消息队列）</p>
<div class="cnblogs_code">
<pre><span style="color: #000000;"># 列出最近访问了共享内存段的进程的创建者的ID和进程ID
ipcs </span>-p -m</pre>
</div>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>参考：</p>
<p>https://www.jianshu.com/p/eb221bf59c54</p>
<p>http://www.cnblogs.com/vamei</p>
<p>https://www.linuxprobe.com/12linux-process-commands.html</p>
<p>&nbsp;</p>