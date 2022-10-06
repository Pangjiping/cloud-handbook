<h1>1. 数据争用</h1>
<p>数据争用在golang中指两个协程同时访问相同的内存空间，并且至少有一个是写操作，就是线程不安全的问题</p>
<p>在golang中有一种经典的数据争用错误</p>
<pre class="language-go"><code>func save(g *data){
    saveToRedis(g)
}

func main(){
    var a&nbsp;&nbsp;  map [int]data
    for _,k:=&nbsp;  range a{
        go save(&amp;k)
    }
}</code></pre>
<p>&nbsp;</p>
<p>可能乍一看并没有什么错误，但这其实是不安全的</p>
<p>在使用range时，变量k是一个堆上地址不变的对象，该地址存储的值会随着range的遍历而发生变化</p>
<p>如果此时我们将变量k的地址放入协程save()，已提供不阻塞的数据存储，那么最后的记过将会是后面的数据覆盖掉前面的数据，并且每一次的数据也不一定是完整的</p>
<p>&nbsp;</p>
<h1>2. race检查</h1>
<p>golang提供了race工具来检测数据争用问题，当检测器在程序中找到数据争用时，将打印报告</p>
<p>该报告包含发生race冲突的协程栈以及此时正在运行的协程栈</p>
<p>race检查可以使用在多个go指令中：</p>
<pre class="language-bash"><code>go test -race mypkg
go run -race main.go
go build -race mycmd
go install -race mypkg</code></pre>
<p>&nbsp;</p>
<h1>3. race检查原理</h1>
<p>race借助了ThreadSanitizer，这是google为了解决大量C++代码的数据争用问题而开发的一个工具，在golang中通过CGO的形式进行调用</p>
<p>从之前的数据争用问题可以看出，当不同的协程访问同一块内存区域并且至少有一个写时，会触发数据争用，当然也有可能不触发</p>
<p>&nbsp;</p>
<h2>3.1 矢量时钟技术</h2>
<p>当两个协程访问同一块内存区域时，一种是协程A结束后，协程B继续执行，另一种则相反</p>
<p>在加互斥锁的情况下，A和B是不可能同时对一个内存区域进行写操作的，所以二者存在明显的顺序关系，这种关系就叫做happened-before</p>
<p>矢量时钟技术用来观察事件之间的happened-before，该技术在分布式系统中广泛应用，用于确定分布式系统中事件的因果关系，也可以用做数据争用的检测</p>
<p>在golang中，有n个协程就会有对应的n个逻辑时钟，而矢量时钟是所有这些逻辑时钟组成的数组，表示形式为 t=&lt;t1, t2, t3, ...&gt;</p>
<p>&nbsp;</p>
<p>在下面这个例子中，有两个协程GA GB同时对一个一个变量count做加一的操作，这就是矢量时钟查看到的happened-before顺序</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405182142992-2090411188.png" alt="" loading="lazy" /></p>
<p>首先GA对变量count加互斥锁，然后对其做++操作</p>
<p>GB能够观察到GA对临界区加锁了，当GA释放锁时，其会更新内部对于协程GA的逻辑时钟，并增加自己的逻辑时钟，完成下一次++操作</p>
<p>&nbsp;</p>
<h2>3.2 何时触发race事件</h2>
<p>在golang中，每个协程在创建之处都会初始化矢量时钟，并在读取或写入事件时修改自己的逻辑时钟</p>
<p>触发race事件的方式主要有两种</p>
<ul>
<li>在golang运行时大量注入触发事件，例如在切片、数组、map、channel时</li>
<li>编译器自动插入，编译器在可能会发生数据争用的地方自动插入race相关指令</li>
</ul>
<p>&nbsp;</p>
<p>主要根据以下四点来判断是否发生数据争用：</p>
<ul>
<li>是否有一个操作是写操作</li>
<li>是否接触了同一块内存</li>
<li>是否是不同的协程</li>
<li>两个事件之间是否是happened-before关系</li>
</ul>
<p>例如当前GB的矢量时钟为&lt;0, 1&gt;，GA只存储了逻辑时钟2，可以被看做&lt;2, x&gt;，x可能是任意值，因此不能判断二者存在争用</p>
<p>当x &gt; 1时，GA -&gt; GB；当x &lt; 1时，二者不存在任何顺序关系，证明发生了数据争用</p>
<p>&nbsp;</p>