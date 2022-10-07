<h1>1. GMP模型</h1>
<ul>
<li>G：goroutine</li>
<li>M：thread线程</li>
<li>P：processor处理器</li>
</ul>
<p>在go中，线程是运行goroutine的实体，调度器的功能是把可运行的goroutine分配到工作线程上。</p>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322131140588-938391965.png" alt="" width="745" height="587" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>全局队列：存放等待运行的G</p>
<p>P的本地队列：和全局队列类似，存放的也是等待运行的G，但是数量有限，不超过256个。新创建一个G时，G优先加入到本地队列，如果队列满了，则会把本地队列中一半的G移动到全局队列</p>
<p>P列表：所有的P都在程序启动时创建，并保存在数组中，最多有GOMAXPROCS个</p>
<p>M：线程想要运行任务就要获取P，从P的本地队列获取G，P队列为空时，M也会尝试从全局队列拿一批G放到P的本地队列，或者从其他P的本地队列偷一半放到自己的P。M运行G，G执行之后，M会从P获取下一个G，不断重复</p>
<p>&nbsp;</p>
<p>goroutine调度器和os调度器是通过M结合起来的，每个M都代表了一个内核线程，os调度器负责把内核线程分配到CPU的核上来执行</p>
<p>&nbsp;</p>
<h1>2. 调度器的设计策略</h1>
<p>设计原则是复用线程，避免频繁的创建、销毁线程，而是对线程的复用</p>
<p>在go中，一个goroutine最多占用CPU 10ms，防止其他goroutine被饿死</p>
<p>&nbsp;</p>
<h2>2.1 work stealing机制</h2>
<p>当本线程无可运行的G时，尝试从其他线程绑定的P中偷取G</p>
<p>&nbsp;</p>
<h2>2.2 hand off机制</h2>
<p>当本线程因为G进行系统调用而阻塞时，线程释放绑定的P，把P转移给其他空闲的线程执行</p>
<p>&nbsp;</p>
<h1>3. go func()调度流程</h1>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220322132131965-722861521.png" alt="" width="724" height="441" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<ol>
<li>通过go func()创建一个goroutine g1</li>
<li>g1优先选择加入一个本地队列，如果本地P都满了则加入全局队列</li>
<li>M获取G开始执行：可以从M挂载的P中获取，或者通过work stealing获取</li>
<li>M执行g1，如果g1发生系统调用或阻塞，则创建一个M或者唤醒一个休眠的M来接管这个本地队列</li>
<li>g1执行完成后，销毁g1，返回结果</li>
</ol>
<p>&nbsp;</p>
<p>参考：</p>
<p>https://www.topgoer.com/%E5%B9%B6%E5%8F%91%E7%BC%96%E7%A8%8B/GMP%E5%8E%9F%E7%90%86%E4%B8%8E%E8%B0%83%E5%BA%A6.html</p>