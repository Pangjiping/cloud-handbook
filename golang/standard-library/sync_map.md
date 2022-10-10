<p><span style="font-size: 14pt;"><strong>1. golang map</strong></span></p>
<p>golang原生map在并发场景下，同时读写是线程不安全的，如论key是否一样，我们可以编写一个测试用例来看看同时读写不同的key会发生什么情况：</p>

```golang
func testForMap() {
    m := make(map[int]int)
    go func() {
        for {
            m[1] = 1
        }
    }()

    go func() {
        for {
            _ = m[2]
        }

    }()
    select {}
}

func main() {
    testForMap()
}
```
<p>&nbsp;</p>
<p>当在终端执行 go run main.go时，会发现系统报错</p>
<pre class="language-bash"><code>fatal error: concurrent map read and map write</code></pre>
<p>&nbsp;</p>
<p>错误很明显，我们在不同的协程中并发的读写了同一个map，虽然是不同的key，还是会发发生并发错误，那么如果想用原生map实现并发操作就必须使用互斥锁或者读写锁来实现。</p>
<p>我们可以定义一个线程安全的map结构体，其中包含了读写锁和一个map：</p>

```golang
type SafeMap struct {
    sync.RWMutex
    m map[int]int
}
```
<p>&nbsp;</p>
<p>然后就可以并发读写这个线程安全的map了：</p>

```golang
func main() {
    safeMap := SafeMap{
        m: make(map[int]int),
    }

    // 读数据
    safeMap.RLock()
    data := safeMap.m[1]
    safeMap.Unlock()
    fmt.Println(data)

    // 写数据
    safeMap.Lock()
    safeMap.m[2] = 1
    safeMap.Unlock()
}
```
<p>&nbsp;</p>
<p>使用读写锁实现的线程安全map已经是一种效率较高的map了，我们都知道在并发编程中读写共享资源加锁是必须的，即使我们使用了封装的线程安全的数据结构，其底层也是使用了锁机制，只是在一定程度上对加锁时机和粒度做了一些优化。</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>2. sync.map</strong></span></p>
<p>sync.map是用读写分离实现的，其思想是空间换时间。和map+lock的实现方式相比，它本身做了一些优化：可以无锁访问read map，而且会优先操作read map，如果只操作read map就可以满足要求，那就不回去操作write map（读写加锁），所以在一些使用场景中它发生锁竞争的频率会远远小于map+lock的实现方式。</p>
<p>&nbsp;</p>
<p><strong>2.1 sync.map的定义</strong></p>

```golang
type Map struct{
  // 互斥锁mu，主要是为dirty服务
  mu Mutex
  // read是只读数据，可以无锁访问
  read atomic.Value
  // 加锁读写，主要处理插入key
  dirty map[interface{}]*entry
  // 统计访问read未命中然后访问dirty的次数
  // 用于将dirty提升为read
  misses int
}
```
<p>&nbsp;</p>
<p>结构体readOnly，顾名思义这就是一个只读结构，其实就是上面map定义中的read</p>

```golang
type readOnly struct{
  m map[interface{}]*entry
  amended bool
}
```
<p>其中m就是一个只读的map，其值entry指针指向真实的数据地址，amended=true表示dirty中有read中不存在的数据</p>
<p>&nbsp;</p>
<p><strong>2.2 sync.map Load</strong></p>
<p>基本使用我就不放了，就是取值操作，取出key对应的value</p>
<p>我们看一下Load方法的流程图</p>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220320130810144-151540689.png" alt="" width="740" height="566" loading="lazy" /></p>
<p>尝试简单分析一下Load数据的流程：</p>
<ol>
<li>首先访问read map，如果read map命中直接返回value</li>
<li>查看amended状态，如果其为false，说明write map中也没有这个key，返回空就好了</li>
<li>如果amended=true，需要加锁在访问一次read map，是一种双重检查机制</li>
<li>如果read中有了这个key，可能是另一个并发的协程在我们第一次无锁查询时已经load了这个key，那么直接返回value</li>
<li>如果read中还是没有，那么去读write，并且把miss+1，然后解锁并返回结果</li>
<li>注意这个miss计数器，当miss计数器的计数长度达到write的大小时，需要将write的kv拷贝给read，然后将write清空</li>
</ol>
<p>&nbsp;</p>
<p><strong>2.3 sync.map Store</strong></p>
<p>Store就是往map中添加新的值或者更新value</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220320131659643-936604026.png" alt="" width="793" height="1081" loading="lazy" /></p>
<p>&nbsp;</p>
<ol>
<li>Store会优先访问read，未命中加锁访问write</li>
<li>Store进行双重检查，同样是因为我们在第一次访问的同时key已经被放入到了read中</li>
<li>dirtyLocked在write为nil会从read中拷贝数据，如果read中数据量很大，可能会出现性能抖动</li>
<li>sync.map不适合频繁插入新的key-value的场景，因为这种操作会频繁加锁访问</li>
</ol>
<p>&nbsp;</p>
<p><strong>2.4 sync.map Delete</strong></p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220320132140798-1752505356.png" alt="" width="715" height="918" loading="lazy" /></p>
<p>&nbsp;</p>
<p>其实可以吧delete视为load的反向操作</p>
<ol>
<li>删除read中存在的key，可以不用加锁</li>
<li>如果要删除read中不存在的或者map中不存在的key，都需要加锁</li>
</ol>
<p>&nbsp;</p>
<p><strong>2.5 sync.map Range</strong></p>
<p>Range可以遍历map</p>
<ol>
<li>Range时，当全部的key都存在于read中是无锁遍历的，效率最高</li>
<li>Range时，如果有部分key存在于write，会加锁一次性拷贝所有的kv到read中</li>
</ol>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>3. 总结</strong></span></p>
<p>sync.map更适合多读的情况，因为多写场景下会频繁加锁而且会发生值拷贝</p>
<p>如果想用多读的场景，可以考虑开源库<a href="https://github.com/orcaman/concurrent-map" target="_blank" rel="nofollow noopener noreferrer" data-from="10680">orcaman/concurrent-map</a>，或者如果对性能要求不是很高也可以选择map+lock的实现方式</p>
<p>&nbsp;</p>
<p>参考：</p>
<p>https://cloud.tencent.com/developer/article/1915119</p>
<p>h<a href="https://stackoverflow.com/questions/45585589/golang-fatal-error-concurrent-map-read-and-map-write/45585833" target="_blank" rel="nofollow noopener noreferrer" data-from="10680">ttps://stackoverflow.com/questions/45585589/golang-fatal-error-concurrent-map-read-and-map-write/45585833</a></p>
<p><a href="https://github.com/golang/go/issues/20680" target="_blank" rel="nofollow noopener noreferrer" data-from="10680">https://github.com/golang/go/issues/20680</a></p>
<p><a href="https://github.com/golang/go/blob/master/src/sync/map.go" target="_blank" rel="nofollow noopener noreferrer" data-from="10680">https://github.com/golang/go/blob/master/src/sync/map.go</a></p>