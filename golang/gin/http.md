<h1>1. hello world</h1>
<p>首先拉取gin开发框架</p>
<pre class="language-bash"><code>go get -u github.com /gin-gonic/gin</code></pre>
<p>&nbsp;</p>
<p>我们从入门的hello world入手看起gin是如何构建一个http服务器的</p>
<pre class="language-go"><code>package main

import "github.com/gin-gonic/gin"

func main() {
    engine := gin.Default()
    engine.GET( "/ping" ,  func (ctx *gin.Context) {
        ctx.JSON(200, gin.H{
            "message" :  "pong" ,
        })
    })
    engine.Run()  // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}</code></pre>
<p>&nbsp;</p>
<p>可以看到gin的最简单使用就需要三个步骤：</p>
<ul>
<li>创建一个gin engine</li>
<li>注册一个get方法的路由</li>
<li>开始监听，默认为8080端口</li>
</ul>
<p>&nbsp;</p>
<h1>2. Engine</h1>
<p>在gin框架中，engine被定义成一个结构体，engine代表gin框架的一个结构体定义，其中包含了路由组、中间件、页面渲染接口、框架配置设置等相关内容</p>
<p>默认的engine可以通过gin.Default进行创建，或者采用gin.New()同样可以创建：</p>
<pre class="language-go"><code>engine1 := gin.Default()
engine2 := gin.New()</code></pre>
<p>&nbsp;</p>
<p>gin.Default()和gin.New()的区别在于gin.Default()也是使用gin.New()创建engine实例，但是会默认使用Logger和Recovery中间件</p>
<p>Logger是负责进行打印并输出日志的中间件，方便程序开发调试，就是我们在终端上看到的[GIN-debug]输出</p>
<p>Recovery中间件的作用是如果程序执行中遇到了panic中断了服务，则Recovery会恢复程序执行，并返回服务器内部500错误</p>
<p>&nbsp;</p>
<h1>3. 处理http请求</h1>
<p>在创建engine实例中，包含很多方法可以处理不同类型的http请求</p>
<p>&nbsp;</p>
<h2>3.1 通用处理</h2>
<p>engine中可以直接进行http请求的处理，在engine中使用Handle方法进行http请求的处理</p>
<p>Handle方法包含三个参数，具体为：</p>
<pre class="language-go"><code>func (group *RouterGroup) Handle(httpMethod, relativePath string, handlers ...HandlerFunc) IRoutes</code></pre>
<ul>
<li>httpMethod：要处理的http请求类型，GET/POST等</li>
<li>relativePath：要解析的接口</li>
<li>handlers：处理对应的请求的代码的定义</li>
</ul>
<p>&nbsp;</p>
<p>示例，Handle处理GET请求：</p>
<pre class="language-go"><code>func main() {
	engine := gin.Default()

	// http://localhost:8080/hello?name=james
	engine.Handle("GET", "/hello", func(ctx *gin.Context) {
		fmt.Println(ctx.FullPath())
		name := ctx.DefaultQuery("name", "pangjiping") // 第二个参数是默认值
		ctx.Writer.Write([]byte("hello " + name))
	})
	engine.Run()
}</code></pre>
<p>&nbsp;</p>
<h2>3.2 分类处理</h2>
<p>除了engine中包含的通用处理方法外，engine还可以按照类型直接进行解析</p>
<p>engine中包含了get/post/delete等请求对应的方法</p>
<p>&nbsp;</p>
<h3>3.2.1 engine.GET()处理GET请求</h3>
<p>engine中包含了GET请求的处理方法</p>
<p>context.DefaultQuery：用来解析GET请求携带的参数，如果没有传入参数则使用默认值，还可以使用context.Query方法来获取GET请求携带的参数</p>
<pre class="language-go"><code>// get
// http://localhost:8080/test01?username=james
engine.GET( "/test01" , func (ctx *gin.Context) {
	fmt.Println(ctx.FullPath())
	username := ctx.DefaultQuery( "username" ,  "pjp" )
	ctx.Writer.Write([]byte(username))
})</code></pre>
<p>&nbsp;</p>
<h3>3.2.2&nbsp;engine.POST()处理POST请求</h3>
<p>可以使用很多种方式来解析post表单的数据，这和我们请求的参数类型有关系</p>
<pre class="language-go"><code>// post
// http://localhost:8080/login
engine.POST( "/login" , func (ctx *gin.Context) {
    fmt.Println(ctx.FullPath())
    username, ok := ctx.GetPostForm("username")
    if ok {
        fmt.Println(username)
    }
    password, ok := ctx.GetPostForm("password")
    if ok {
        fmt.Println(password)
    }
    ctx.Writer.Write([]byte("hello"))
})</code></pre>
<p>&nbsp;</p>
<h3>3.2.3 engine.DELETE()处理DELETE请求</h3>
<pre class="language-go"><code>// delete
// http://localhost/user/:id
engine.DELETE("/user/:id" , func (ctx *gin.Context) {
    userID := ctx.Param("id")
    fmt.Println(userID)
    ctx.Writer.Write([]byte("goodbye " + userID))
})</code></pre>
<p>&nbsp;</p>
<h1>4. Run()</h1>
<p>engine.Run()其实底层就是调用了net/http标准库的ListenAndServer()函数</p>
<pre class="language-go"><code>// Run attaches the router to a http.Server and starts listening and serving HTTP requests.
// It is a shortcut for http.ListenAndServe(addr, router)
// Note: this method will block the calling goroutine indefinitely unless an error happens.
func (engine *Engine) Run(addr ...string) (err error) {
	defer func() { debugPrintError(err) }()

	if engine.isUnsafeTrustedProxies() {
		debugPrint("[WARNING] You trusted all proxies, this is NOT safe. We recommend you to set a value.\n" +
			"Please check https://pkg.go.dev/github.com/gin-gonic/gin#readme-don-t-trust-all-proxies for details.")
	}

	address := resolveAddress(addr)
	debugPrint("Listening and serving HTTP on %s\n", address)
	err = http.ListenAndServe(address, engine.Handler())
	return
}</code></pre>
<p>&nbsp;</p>