<p>go在线程的基础上实现了用户态更加轻量级的写成，线程栈为了防止stack overflow，默认大小一般是2MB，而在go中，协程栈在初始化时是2KB</p>
<p>go中的栈是可以扩容的，在64位操作系统上最大为1GB</p>
<p>&nbsp;</p>
<h1>1. newstack()函数</h1>
<p>在函数序言阶段如果判断出需要扩容，则会跳转调用运行时morestack_noctxt函数，函数调用链为：</p>
<p>morestack_noctxt() -&gt; morestack() -&gt; newstack()</p>
<p>核心代码位于 newstack() 函数中，newstack()函数不仅会处理扩容，还会处理协程的抢占</p>
<p>下面看一下newstack()函数的核心实现：</p>
<pre class="language-go"><code>func newstack() {
    oldsize := gp.stack.hi - gp.stack.lo

    // 两倍于原来大小
    newsize := oldsize * 2

    // 需要的栈太大，直接溢出
    if newsize &gt; maxstacksize {
        throw( "stack overflow" )
    }

    // goroutine必须是正在执行过程中才会调用newstack
    // 所以这个状态一定是Grunning或者Gscanrunning
    casgstatus(gp, _Grunning, _Gcopystack)

    // gp的处于Gcopystack状态，当我们对栈进行复制时并发GC不会扫描此栈
    // 栈的复制
    copystack(gp, newsize)
    casgstatus(gp, _Gcopystack, _Grunning)

    // 继续执行
    gogo(&amp;gp.sched)
}</code></pre>
<p>&nbsp;</p>
<p>什么是gp？</p>
<p>gp就是当前协程的结构体：</p>
<pre class="language-go"><code>type g  struct {
    stack stack
    stackguard0 uintptr
    stackguard1 uintptr
    ... 
}

type stack  struct {
    lo uintptr  // 8 bytes
    hi uintptr
}</code></pre>
<p>&nbsp;</p>
<p>gp.stack.hi - gp.stack.lo就是在计算当前协程栈的大小</p>
<p>newstack()函数首先通过栈底地址与栈顶地址计算出旧栈的大小，并计算新栈的大小，新栈大小为旧栈的两倍大。在64为操作系统中，如果栈大小超过了1GB(maxstacksize)则直接报错stack overflow</p>
<p>&nbsp;</p>
<h1>2. 栈转移</h1>
<p>栈扩容的重要一步就是将旧栈的内容转移到新栈中，栈扩容首先将协程的状态设置为 _Gcopystack，以便在垃圾回收时不会扫描该栈带来错误</p>
<p>栈复制并不是向内存复制一样简单，需要处理很多其他地址的指针转移的问题，同时为了应对频繁的栈调整，linux操作系统下，会对2/4/8/16KB的小栈进行专门的优化</p>
<p>在全局以及每个逻辑处理器中预先分配这些小栈的缓存池，避免频繁申请堆内存</p>
<p>对于大栈，其大小不确定，孙然也有一个全局的缓存池，但不会预先放入多个栈，当栈被销毁时，如果被销毁的栈为大栈则放入全局缓存池中&nbsp;</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220328233034840-705907750.png" alt="" width="766" height="520" loading="lazy" /></p>
<p>&nbsp;</p>
<p>在分配到栈后，如果有指针指向旧栈，那么需要将其调整到新栈中</p>
<p>在调整时有一个额外的步骤是调整sudog，由于通道在阻塞的情况下存储的元素可能指向了站上的指针，因此需要调整</p>
<p>接着需要将旧栈的大小复制到新栈中，这涉及借助memmove函数进行内存复制</p>
<p>扩容最关键的一步是在新栈中调整指针，因为新栈中的指针可能指向旧栈，旧栈一旦释放后会出现问题。</p>
<p>在栈扩容的时候，copystack函数会遍历新栈上虽有的栈帧信息，并遍历其中所有可能指针的位置，一旦发现指针指向旧栈，就会调整当前的指针使其指向新栈</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220328234023782-1609484019.png" alt="" width="802" height="514" loading="lazy" /></p>
<p>&nbsp;</p>