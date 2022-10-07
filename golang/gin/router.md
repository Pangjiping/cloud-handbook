<h1>1. 路由组</h1>
<p>在实际的项目开发中，均是模块化开发</p>
<p>同一模块内的功能接口，往往会有相同的接口前缀，这种可以用路由组来进行分类处理。</p>
<p>比如下面这几组接口：</p>
<pre class="language-bash"><code>注册：http: //localhost:8080/user/register
登陆：http: //localhost:8080/user/login
用户信息：http: //localhost:8080/user/info</code></pre>
<p>&nbsp;</p>
<p>gin框架可以使用路由组来实现对路由的分类</p>
<p>路由组是router.Group中的一个方法，对于请求进行分组</p>

```golang
func main() {
	engine := gin.Default()

	// 注册路由组
	routerGroup := engine.Group("/user")

	routerGroup.POST("/register", func(ctx *gin.Context) {})
	routerGroup.POST("/login", func(ctx *gin.Context) {})
	routerGroup.GET("/info", func(ctx *gin.Context) {})

	engine.Run()
}
```

<p>&nbsp;</p>
<h1>2. 中间件</h1>
<p>&nbsp;在实际的业务开发中，一个完整的系统可能要包含鉴权认证、权限管理、安全检查、日志记录等多个维度的系统支持</p>
<p>鉴权认证、权限管理、安全检查等业务都是属于全系统的业务，和具体的业务没有直接关联</p>
<p>因此在开发中，为了更好的梳理系统架构，可以将以上这些业务单独抽离出来，以插件化的方式进行对接</p>
<p>这种通用业务独立开发并灵活配置使用的组件，称之为中间件，其位于服务器和实际业务处理程序之间</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220330160442459-691120633.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>2.1 gin的中间件</h2>
<p>在gin中，中间件的类型定义如下：</p>

```golang
// HandlerFunc defines the handler used by gin middleware as return value
type HandlerFunc  func (*Context)
```

<p>HandlerFunc是一个函数类型，接收一个Context参数。用于编写程序处理函数并返回HandleFunc类型，作为中间件定义</p>
<p>&nbsp;</p>
<h2>2.2 中间件Use用法</h2>
<p>关于初始化gin engine的gin.Default()方法的实现中也使用了两个中间件</p>

```golang
// Default returns an Engine instance with the Logger and Recovery middleware already attached.
func Default() *Engine {
    debugPrintWARNINGDefault()
    engine := New()
    engine.Use(Logger(), Recovery())
    return engine
}
```

<p>&nbsp;</p>
<p>我们可以跳转到Logger()中间件的定义，去看看实现一个中间件的格式是什么</p>

```golang
// Logger instances a Logger middleware that will write the logs to gin.DefaultWriter.
// By default, gin.DefaultWriter = os.Stdout.
func Logger() HandlerFunc {
    return LoggerWithConfig(LoggerConfig{})
}
```

<p>&nbsp;</p>
<h2>2.3 自定义中间件</h2>
<p>根据上文关于中间件的描述中，我们可以自定义一个特殊需求的中间件，中间件类型是函数，有两条标准：</p>
<ul>
<li>func函数</li>
<li>返回值类型为HandlerFunc</li>
</ul>
<p>比如我们现在有一个需求，实现一个中间件，其功能就是打印出请求的path和method：</p>

```golang
// RequestInfos 实现一个中间件
func RequestInfos() gin.HandlerFunc {
    return func (ctx *gin.Context) {
        path := ctx.FullPath()
        method := ctx.Request.Method
        fmt.Println(path, method)
    }
}
```

<p>　　</p>
<p>使用或者注册中间件时有两种方式，一种是直接使用engine.Use()，那么所有接口都会经过这个中间件处理</p>

```golang
// 使用中间件，所有接口都经过这个中间件
engine.Use(RequestInfos())
```

<p>　　</p>
<p>或者为某一个处理注册一个中间件，那么只有这一个请求会经过该中间件</p>

```golang
engine.GET( "/query" , RequestInfos(),  func (ctx *gin.Context) {
	ctx.JSON(http.StatusOK,  map [string] interface {}{
		"code" : 1,
		"message" : ctx.FullPath(),
	})
})
```

<p>　</p>
<h2>2.4 context.Next函数</h2>
<p>在上面自定义中间件RequestInfos()中，打印了请求的路径和请求的method，接着去执行了正常的业务处理函数</p>
<p>如果我们想输出业务处理的结果，就应该使用context.Next来实现</p>
<p>context.Next可以将中间件代码一分为二：</p>
<ul>
<li>Next()之前的代码会在请求处理之前执行</li>
<li>当中间件执行流遇到context.Next时，会中断执行，转而执行业务逻辑</li>
<li>当业务逻辑执行完之后，再次回到Next函数处，继续向下执行中间件逻辑，从而获取业务执行之后的结果</li>
</ul>
<p>&nbsp;具体用法如下：</p>

```golang
func RequestInfos() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		path := ctx.FullPath()
		method := ctx.Request.Method
		fmt.Println(path, method)

		ctx.Next() // 在此处一分为二

		fmt.Println(ctx.Writer.Status())
	}
}
```
<p>　　</p>