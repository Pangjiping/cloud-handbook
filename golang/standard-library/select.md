<p>在golang中，select一般是和chan一起工作的，用于同时监听多个chan的信息，其实用方法和switch差不多：</p>
<pre class="language-go"><code>select {
case &lt;-ch1:
// ...
case x := &lt;-ch2:
// ...
case ch3 &lt;- y:
// ...
default :
// ...
}</code></pre>
<p>　</p>
<p>和switch不同的是，每个case语句都必须对应channel的读写操作，select语句会陷入阻塞，直到一个或者多个channel可以读写才能恢复</p>
<p>&nbsp;</p>
<h1>1. select的阻塞机制</h1>
<h2>1.1 select的随机选择</h2>
<p>当多个channel都具备了读写能力的时候，也就是说多个case都可以执行的条件下，select会执行哪一个？答案是随机执行一个</p>
<p>我们可以写一个简单的demo，来看一下select实际的执行情况</p>
<pre class="language-go"><code>func main() {
	c1 := make(chan int, 10)
	c2 := make(chan int, 10)
	for i := 0; i &lt; 10; i++ {
		c1 &lt;- i
		c2 &lt;- i
	}
	for {
		select {
		case &lt;-c1:
			fmt.Println("random 1")
		case &lt;-c2:
			fmt.Println("random 2")
		default:
			//fmt.Println("default")
		}
	}
}</code></pre>
<p>&nbsp;</p>
<p>当两个channel c1和c2都可以读取数据时，select的执行选择是随机的</p>
<p>&nbsp;</p>
<h2>1.2 select的阻塞和控制</h2>
<p>如果select中没有任何的channel准备好，那么当前的select所在的协程会陷入阻塞，直到有一个case满足条件</p>
<p>通常在实践中不想一直阻塞的话，为了避免这种情况可以加上default分支，或者加入一个超时定时器</p>
<pre class="language-go"><code>c := make( chan int, 1)
select {
case &lt;-c:
    fmt.Println( "got it" )
case &lt;-time.After(10 * time.Second):
    fmt.Println( "timeout" )
}</code></pre>
<p>&nbsp;</p>
<p>加入定时器超时的方式在实际中很常用，可以与超时重试或者超时直接报错等方式结合</p>
<p>&nbsp;</p>
<h2>1.3 select循环等待</h2>
<p>通常我们对于select的需求，就是想让它一直阻塞，比如我们想要监听一个chan所下达的任务</p>
<p>for select结构就是为此而生的，通常的做法下，select分支需要配合定时器来使用，实现超时通知或者定时任务等功能</p>
<pre class="language-go"><code>func main() {
    c := make( chan int, 1)
    tick := time.Tick(time.Second)

    for {
        select {
        case &lt;-c:
            fmt.Println("got it")
        case &lt;-tick:
            fmt.Println("crontab")
        case &lt;-time.After(800 * time.Millisecond):
            fmt.Println("timeout")
        }
    }
}</code></pre>
<p>　</p>
<p>注意这里的两个定时器time.Tick和time.After</p>
<p>time.After在每次for中都会被重置，所以它在记录进入一次for循环的800ms时间</p>
<p>time.Tick是在for循环外部初始化的，所以它会按照时间累计，只要时间满1s就会执行一次定时任务</p>
<p>所以这两个定时器一个是为了超时重试，一个是为了执行一个间隔为1s的定时任务</p>
<p>&nbsp;</p>
<h2>1.4 select和nil channel</h2>
<p>一个为nil的channel，读写都处于阻塞状态，如果它在case分支中，select将永远不会执行</p>
<p>nil channel这种特性让我们可以设计一些特殊的数据传输方法，比如现在的需求是轮流向两个channel发送数据</p>
<p>那么我们可以在给一个channel发送完数据之后，将其置nil</p>
<pre class="language-go"><code>func main() {
    c1 := make( chan int)
    c2 := make( chan int)
    go func () {
        for i := 0; i &lt; 2; i++ {
            select {
            case c1 &lt;- 1:
                c1 = nil
            case c2 &lt;- 2:
                c2 = nil
            }
        }
    }()

    fmt.Println(&lt;-c1)
    fmt.Println(&lt;-c2)
}</code></pre>
<p>　　</p>
<h1>2. select的底层原理</h1>
<p>select在运行时会调用核心函数selectgo</p>
<pre class="language-go"><code>func selectgo(cas0 *scase, order0 *uint16, ncases int) (int, bool) {
    pollorder := order1[:ncases:ncases]
    lockorder := order1[ncases:][:ncases:ncases]
    for i := 1; i &lt; ncases; i++ {
        j := fastrandn(uint32(i + 1))
        pollorder[i] = pollorder[j]
        pollorder[j] = uint16(i)
    }
}</code></pre>
<p>　　</p>
<p>每一个case在运行时都是一个scase结构体，存放了chan和chan中的元素类型</p>
<pre class="language-go"><code>type scase  struct {
    c&nbsp;&nbsp;*hchan
    elem unsafe.Pointer
    kind uint16
    ...
}</code></pre>
<p>　　</p>
<p>其中的kind代表case的类型，主要有四种类型：</p>
<ul>
<li>caseNil</li>
<li>caseRecv</li>
<li>caseSend</li>
<li>caseDefault</li>
</ul>
<p>分别对应着四种case的操作，对于每一种分支，select会执行不同的函数</p>
<p>&nbsp;</p>
<p>在selectgo中，有两个重要的序列结构：pollorder和lockorder</p>
<p>pollorder是一个乱序的case序列，就是函数体中那一段for循环代码，算法类似于洗牌算法，保证了select的随机性</p>
<p>lockorder是按照大小对chan地址排序的算法，对所有的scase按照其chan在堆区的地址大小，使用了小顶堆算法来排序</p>
<p>selectgo会按照该次序对select中的case加锁，按照地址排序的顺序加锁是为了防止多个协程并发产生死锁</p>
<p>&nbsp;</p>
<p>当所有scase中的chan加锁完毕之后，就开始第一轮循环找出是否有准备好的分支：</p>
<ul>
<li>如果是caseNil，忽略</li>
<li>如果是caseRecv，判断是否有正在等待写入的协程，如果有跳转到recv分支；判断缓冲区是否有数据，如果有则跳转bufrecv分支</li>
<li>如果是caseSend，判断是否有正在等待读取的协程，如果有跳转到send分支；判断缓冲区是否有空余，如果有跳转bufsend分支</li>
<li>如果是caseDefault，记录下来，当循环结束发现没有其他case准备好时，执行default</li>
</ul>
<p>&nbsp;</p>
<p>当select完成一轮循环不能直接退出时，意味着当前协程需要进入阻塞状态等到至少一个case具备执行条件</p>
<p>不管是读取还是写入chan都需要创建一个新的sudog并将其放入指定通道的等待队列，之后重新进入阻塞状态</p>
<p>当select case中任意一个case不再阻塞时，当前协程将会被唤醒</p>
<p>要注意的是，最后需要将sudog结构体在其他通道的等待队列中出栈，因为当前协程已经能够正常运行，不需要再被其他通道唤醒</p>
<p>&nbsp;</p>