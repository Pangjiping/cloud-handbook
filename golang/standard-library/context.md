<h1><span style="font-size: 14pt;"><strong>1. 上下文context</strong></span></h1>
<p>上下文context.Context在golang中用于设置截止日期、同步信号、传递请求相关值的结构体。</p>
<p>上下文概念和goroutine有着较为密切的关系，是go中独有的设计。</p>
<p>&nbsp;</p>
<p>在goroutine构成的树形结构中对信号进行同步以减少计算资源的浪费是context最大的作用。</p>
<p>go服务中每一个请求都是通过单独的goroutine处理的，http/rpc请求的处理器会启动新的goroutine访问数据库和其他服务。</p>
<p>我们可能会创建多个goroutine来处理一次请求，而context.Context的作用就是在不同的goroutine之间同步请求特定数据、取消信号以及处理请求的截止日期。</p>
<p>每一个context.Context都会从最顶层的goroutine一层一层传递给最下层。context.Context可以在上层goroutine执行出现错误时，将信号及时同步给下层。</p>
<h1><span style="font-size: 14pt;"><strong>2. 使用context同步信号</strong></span></h1>

```golang
func main() {

	// 带1s超时的context
	// 指明了我们只有一秒的时间处理handle这个协程
	ctx, cancelFunc := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancelFunc()

	go handle(ctx, 500*time.Millisecond)

	// main协程监听超时
	select {
	case &lt;-ctx.Done():
		fmt.Println("main", ctx.Err())
	}
}

func handle(ctx context.Context, duration time.Duration) {

	// handle协程监听超时或任务完成--duration时间处理任务
	select {
	case &lt;-ctx.Done():
		fmt.Println("handle", ctx.Err())
	case &lt;-time.After(duration):
		fmt.Println("process request with ", duration)
	}
}
```
<p>&nbsp;</p>
<p>在上述的例子中，我们带超时的context有1s的超时时间，而我们需要处理的协程需要耗费500ms，所以协程不会被context打断，如果我们将handle协程的处理时间增加到2000ms，就会发现主协程的context中断了handle协程的执行：</p>
<pre class="language-bash"><code>handle context deadline exceeded
main context deadline exceeded</code></pre>
<p>&nbsp;</p>
<p>这个例子就是简单的利用context进行协程同步或者取消下游协程，多个goroutine同时订阅ctx.Done()管道中的消息，一旦收到取消信号就立即停止当前正在执行的工作。</p>
<p>&nbsp;</p>
<h1><span style="font-size: 14pt;"><strong>3. 默认上下文</strong></span></h1>
<p>context包中最常用的方法还是context.Background和context.TODO，这两个方法都会返回预先初始化好的私有变量background和todo，他们会在一个go程序中被复用。</p>
<p>从源代码来看，context.Background和context.TODO只是互为别名，没有太大差别，只是在使用和语义上稍有不同：</p>
<ul>
<li>context.Background是上下文的默认值，所有其他上下文都应该从他衍生而来</li>
<li>context.TODO应该仅在不确定该使用哪种上下文时使用</li>
</ul>
<p>在多数情况下，如果当前函数没有上下文作为入参，我们都会使用context.Background作为起始的上下文传递</p>
<p>&nbsp;</p>
<h1><span style="font-size: 14pt;"><strong>4. 取消信号</strong></span></h1>
<p>context.WithCancel函数能够从context.Context中衍生出一个新的子上下文并用于取消该上下文的函数。一旦我们执行返回的取消函数，当前上下文以及它的子上下文都会被取消，所有的goroutine都会收到这一取消信号。</p>
<p>我们直接从context.WithCancel函数的实现看看它做了什么：</p>
<ul>
<li>context.newCancelCtx将传入的上下文包装成私有结构体context.cancelCtx</li>
<li>context.propagateCancel会构建父子上下文之间的关联，当父上下文被取消时，子上下文也会被取消</li>
</ul>
<pre class="language-go"><code>func WithCancel(parent Context) (ctx Context, cancel CancelFunc) {
	c := newCancelCtx(parent)
	propagateCancel(parent, &amp;c)
	return &amp;c, func() { c.cancel(true, Canceled) }
}</code></pre>
<p>&nbsp;</p>

```golang
func propagateCancel(parent Context, child canceler) {
	done := parent.Done()
	if done == nil {
		return // 父上下文不会触发取消信号
	}
	select {
	case &lt;-done:
		child.cancel(false, parent.Err()) // 父上下文已经被取消
		return
	default:
	}

	if p, ok := parentCancelCtx(parent); ok {
		p.mu.Lock()
		if p.err != nil {
			child.cancel(false, p.err)
		} else {
			p.children[child] = struct{}{}
		}
		p.mu.Unlock()
	} else {
		go func() {
			select {
			case &lt;-parent.Done():
				child.cancel(false, parent.Err())
			case &lt;-child.Done():
			}
		}()
	}
}
```
<p>　　</p>
<p>上述函数包含了与父上下文相关的三种不同情况：</p>
<ul>
<li>当parent.Done() == nil，也就是parent不会触发取消事件时，当前函数会直接返回</li>
<li>当child的继承链包含可以取消的上下文时，会判断parent是否已经触发了取消信号。如果已经被取消，child会立即被取消；如果被有被取消，child会加入到parent的children列表中，等待parent的取消信号</li>
<li>当parent上下文是开发者自定义的类型，实现了Context接口并在Done()方法中返回了非空的管道时，运行一个新的goroutine同时监听parent.Done()和child.Done()两个chan，在parent.Done()关闭时调用child.cancel取消上下文</li>
</ul>
<p>context.propagateCancel的作用是在parent和child之间同步取消和结束的信号，保证在parent被取消时，<span style="font-family: monospace;">child</span>也会收到对应的信号，不会出现状态不一致的情况</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>5. 传值方法</strong></span></p>
<p>如何使用上下文传值，context包的context.WithValue能从父上下文中创建一个子上下文，传值的子上下文使用context.valueCtx类型</p>

```golang
func WithValue(parent Context, key, val interface{}) Context {
	if key == nil {
		panic("nil key")
	}
	if !reflectlite.TypeOf(key).Comparable() {
		panic("key is not comparable")
	}
	return &amp;valueCtx{parent, key, val}
}
```
<p>&nbsp;</p>
<p>context.valueCtx结构体会将除了value之外的Err、Deadline等方法代理到父上下文中，它只会响应context.valueCtx.Value方法，该方法的实现：</p>

```golang
type valueCtx struct {
	Context
	key, val interface{}
}

func (c *valueCtx) Value(key interface{}) interface{} {
	if c.key == key {
		return c.val
	}
	return c.Context.Value(key)
}
```
<p>&nbsp;</p>
<p>如果context.valueCtx中存储的键值对与context.valueCtx.Value方法中传入的参数不匹配，就会从父上下文中查找该键对应的值到某个父上下文中返回nil或者查找到对应的值</p>