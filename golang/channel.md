<p data-pid="IWjz9B0i">转载：https://zhuanlan.zhihu.com/p/27917262</p>
<p data-pid="IWjz9B0i">&nbsp;</p>
<p data-pid="IWjz9B0i">以一个简单的channel应用开始，使用goroutine和channel实现一个任务队列，并行处理多个任务。</p>
<pre class="language-go"><code>func main(){
	//带缓冲的channel
	ch := make( chan Task, 3)

	//启动固定数量的worker
	for i := 0; i&lt; numWorkers; i++ {
		go worker(ch)
	}

	//发送任务给worker
	hellaTasks := getTaks()

	for _, task :=  range hellaTasks {
		ch &lt;- task
	}

	...
}

func worker(ch  chan Task){
	for {
		//接受任务
		task := &lt;- ch
		process(task)
	}
}</code></pre>
<p>　　</p>
<p data-pid="oegQnvMg">从上面的代码可以看出，使用golang的goroutine和channel可以很容易的实现一个生产者-消费者模式的任务队列，相比<a class=" wrap external" href="https://link.zhihu.com/?target=http%3A//lib.csdn.net/base/java" target="_blank" rel="nofollow noopener noreferrer" data-za-detail-view-id="1043">Java</a>, c++简洁了很多。channel可以天然的实现了下面四个特性：&nbsp;</p>
<ul>
<li data-pid="9ThC6tVe">goroutine安全&nbsp;</li>
<li data-pid="jPXUO3o_">在不同的goroutine之间存储和传输值 - 提供FIFO语义(buffered channel提供)&nbsp;</li>
<li data-pid="nlmQ9LKP">可以让goroutine block/unblock</li>
</ul>
<p data-pid="3clTVmot">那么channel是怎么实现这些特性的呢？下面我们看看当我们调用make来生成一个channel的时候都做了些什么。</p>
<p data-pid="3clTVmot">&nbsp;</p>
<h2>1. make chan</h2>
<p data-pid="wpOi1k-x">上述任务队列的例子第三行，使用make创建了一个长度为3的带缓冲的channel，channel在底层是一个hchan结构体，位于src/runtime/chan.go里。其定义如下:</p>
<pre class="language-go"><code>type hchan struct {
	qcount   uint           // total data in the queue
	dataqsiz uint           // size of the circular queue
	buf      unsafe.Pointer // points to an array of dataqsiz elements
	elemsize uint16
	closed   uint32
	elemtype *_type // element type
	sendx    uint   // send index
	recvx    uint   // receive index
	recvq    waitq  // list of recv waiters
	sendq    waitq  // list of send waiters

	// lock protects all fields in hchan, as well as several
	// fields in sudogs blocked on this channel.
	//
	// Do not change another G's status while holding this lock
	// (in particular, do not ready a G), as this can deadlock
	// with stack shrinking.
	lock mutex
}</code></pre>
<p>&nbsp;</p>
<p data-pid="NLGq9IW4">make函数在创建channel的时候会在该进程的heap区申请一块内存，创建一个hchan结构体，返回执行该内存的指针，所以获取的的ch变量本身就是一个指针，在函数之间传递的时候是同一个channel。</p>
<p data-pid="zXbJlIFb">hchan结构体使用一个环形队列来保存groutine之间传递的数据(如果是缓存channel的话)，使用两个list保存像该chan发送和从该chan接收数据的goroutine，还有一个mutex来保证操作这些结构的安全。</p>
<p data-pid="zXbJlIFb">&nbsp;</p>
<h2>2. 发送和接收</h2>
<p data-pid="e7IVD3QS">向channel发送和从channel接收数据主要涉及hchan里的四个成员变量，借用Kavya ppt里的图示，来分析发送和接收的过程。&nbsp;</p>
<div class="RichText-gifPlaceholder">
<div class="GifPlayer" data-size="normal" data-za-detail-view-path-module="GifItem"><img class="ztext-gif" style="display: block; margin-left: auto; margin-right: auto;" src="https://pic1.zhimg.com/v2-c2549285cd3bbfd1fcb9a131d8a6c40c_b.jpg" width="514" height="396" data-thumbnail="https://pic1.zhimg.com/v2-c2549285cd3bbfd1fcb9a131d8a6c40c_b.jpg" data-size="normal" />
<div class="GifPlayer-icon">&nbsp;</div>
</div>
</div>
<p data-pid="2R8C3aUj">还是以前面的任务队列为例:</p>
<pre class="language-go"><code>//G1
func main(){
    ...

    for _, task :=  range hellaTasks {
        ch &lt;- task&nbsp;&nbsp;&nbsp;  //sender
    }

    ...
}

//G2
func worker(ch  chan Task){
    for {
       //接受任务
       task := &lt;- ch&nbsp;  //recevier
       process(task)
    }
}</code></pre>
<div class="highlight">&nbsp;</div>
<p data-pid="LLjoLFX_">其中G1是发送者，G2是接收，因为ch是长度为3的带缓冲channel，初始的时候hchan结构体的buf为空，sendx和recvx都为0，当G1向ch里发送数据的时候，会首先对buf加锁，然后将要发送的数据copy到buf里，并增加sendx的值，最后释放buf的锁。然后G2消费的时候首先对buf加锁，然后将buf里的数据copy到task变量对应的内存里，增加recvx，最后释放锁。整个过程，G1和G2没有共享的内存，底层通过hchan结构体的buf，使用copy内存的方式进行通信，最后达到了共享内存的目的，这完全符合CSP的设计理念</p>
<p data-pid="LLjoLFX_">&nbsp;</p>
<p data-pid="7I7lXGpo">一般情况下，G2的消费速度应该是慢于G1的，所以buf的数据会越来越多，这个时候G1再向ch里发送数据，这个时候G1就会阻塞，那么阻塞到底是发生了什么呢？</p>
<p data-pid="7I7lXGpo">&nbsp;</p>
<h2>3. Goroutine Pause/Resume</h2>
<p data-pid="-_qYk3Yp">goroutine是Golang实现的用户空间的轻量级的线程，有runtime调度器调度，与操作系统的thread有多对一的关系，相关的数据结构如下图:&nbsp;</p>
<p><img class="origin_image zh-lightbox-thumb lazy" style="display: block; margin-left: auto; margin-right: auto;" src="https://pic1.zhimg.com/80/v2-6b7eb0b02fb5c275492909aeabfbb428_1440w.png" width="711" height="479" data-caption="" data-size="normal" data-rawwidth="1266" data-rawheight="853" data-original="https://pic1.zhimg.com/v2-6b7eb0b02fb5c275492909aeabfbb428_r.jpg" data-actualsrc="https://pic1.zhimg.com/v2-6b7eb0b02fb5c275492909aeabfbb428_b.png" data-lazy-status="ok" /></p>
<p class="ztext-empty-paragraph">&nbsp;</p>
<p data-pid="GmH51h-6">其中M是操作系统的线程，G是用户启动的goroutine，P是与调度相关的context，每个M都拥有一个P，P维护了一个能够运行的goutine队列，用于该线程执行。</p>
<p data-pid="PhZJDRSJ">当G1向buf已经满了的ch发送数据的时候，当runtine检测到对应的hchan的buf已经满了，会通知调度器，调度器会将G1的状态设置为waiting, 移除与线程M的联系，然后从P的runqueue中选择一个goroutine在线程M中执行，此时G1就是阻塞状态，但是不是操作系统的线程阻塞，所以这个时候只用消耗少量的资源。</p>
<p data-pid="PznMm-LF">那么G1设置为waiting状态后去哪了？怎们去resume呢？我们再回到hchan结构体，注意到hchan有个sendq的成员，其类型是waitq，查看源码如下：&nbsp;</p>
<pre class="language-go"><code>type hchan struct { 
    ... 
    recvq waitq  // list of recv waiters 
    sendq waitq  // list of send waiters 
    ... 
} 
// 
type waitq struct { 
    first *sudog 
    last *sudog 
}</code></pre>
<div class="highlight">&nbsp;</div>
<p data-pid="Z7GrqDww">实际上，当G1变为waiting状态后，会创建一个代表自己的sudog的结构，然后放到sendq这个list中，sudog结构中保存了channel相关的变量的指针(如果该Goroutine是sender，那么保存的是待发送数据的变量的地址，如果是receiver则为接收数据的变量的地址，之所以是地址，前面我们提到在传输数据的时候使用的是copy的方式)&nbsp;</p>
<p><img class="origin_image zh-lightbox-thumb lazy" style="display: block; margin-left: auto; margin-right: auto;" src="https://pic4.zhimg.com/80/v2-eb2e209ff1c84b4657c8d9862707789b_1440w.png" width="572" height="367" data-caption="" data-size="normal" data-rawwidth="852" data-rawheight="547" data-original="https://pic4.zhimg.com/v2-eb2e209ff1c84b4657c8d9862707789b_r.jpg" data-actualsrc="https://pic4.zhimg.com/v2-eb2e209ff1c84b4657c8d9862707789b_b.png" data-lazy-status="ok" /></p>
<p class="ztext-empty-paragraph">&nbsp;</p>
<p data-pid="XHe4FWLE">当G2从ch中接收一个数据时，会通知调度器，设置G1的状态为runnable，然后将加入P的runqueue里，等待线程执行.&nbsp;</p>
<p><img class="origin_image zh-lightbox-thumb lazy" style="display: block; margin-left: auto; margin-right: auto;" src="https://pic1.zhimg.com/80/v2-b57542e446915d4d86693136900c30f0_1440w.png" width="634" height="423" data-caption="" data-size="normal" data-rawwidth="1254" data-rawheight="837" data-original="https://pic1.zhimg.com/v2-b57542e446915d4d86693136900c30f0_r.jpg" data-actualsrc="https://pic1.zhimg.com/v2-b57542e446915d4d86693136900c30f0_b.png" data-lazy-status="ok" /></p>
<p class="ztext-empty-paragraph">&nbsp;</p>
<h2>4. wait empty channel&nbsp;</h2>
<p data-pid="6zigFsUq">前面我们是假设G1先运行，如果G2先运行会怎么样呢？如果G2先运行，那么G2会从一个empty的channel里取数据，这个时候G2就会阻塞，和前面介绍的G1阻塞一样，G2也会创建一个sudog结构体，保存接收数据的变量的地址，但是该sudog结构体是放到了recvq列表里，当G1向ch发送数据的时候，runtime并没有对hchan结构体题的buf进行加锁，而是直接将G1里的发送到ch的数据copy到了G2 sudog里对应的elem指向的内存地址！</p>
<p class="ztext-empty-paragraph">&nbsp;</p>
<p><img class="origin_image zh-lightbox-thumb lazy" style="display: block; margin-left: auto; margin-right: auto;" src="https://pic3.zhimg.com/80/v2-4466a9880e997d27357b778583a7e166_1440w.png" width="609" height="434" data-caption="" data-size="normal" data-rawwidth="1200" data-rawheight="855" data-original="https://pic3.zhimg.com/v2-4466a9880e997d27357b778583a7e166_r.jpg" data-actualsrc="https://pic3.zhimg.com/v2-4466a9880e997d27357b778583a7e166_b.png" data-lazy-status="ok" /></p>
<p class="ztext-empty-paragraph">&nbsp;</p>
<h2>5. 总结&nbsp;</h2>
<p data-pid="3bQ-zzVT">Golang的一大特色就是其简单高效的天然并发机制，使用goroutine和channel实现了CSP模型。理解channel的底层运行机制对灵活运用golang开发并发程序有很大的帮助，看了Kavya的分享，然后结合golang runtime相关的源码(源码开源并且也是golang实现简直良心！),对channel的认识更加的深刻，当然还有一些地方存在一些疑问，比如goroutine的调度实现相关的，还是要潜心膜拜大神们的源码！</p>