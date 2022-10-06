<h1>1. 获取参数</h1>
<h2>1.1 直接获取参数</h2>
<p>我们经常需要获取用户传递的数据，包括GET、POST等方式的请求，beego里面会自动解析这些数据，可以通过下面的方式获取数据</p>
<pre class="language-go"><code>GetString(key string) string
GetStrings(key string) []string
GetInt(key string) (int64, error)
GetBool(key string) (bool, error)
GetFloat(key string) (float64, error)</code></pre>
<p>&nbsp;</p>
<p>使用例子如下，我们需要直到我们想要获取哪个key的参数：</p>
<pre class="language-go"><code>func (this *MainController) Post() {
    jsoninfo := this.GetString( "jsoninfo" )
    if jsoninfo ==  "" {
        this.Ctx.WriteString( "jsoninfo is empty" )
        return
    }
}</code></pre>
<p>&nbsp;</p>
<p>如果需要的数据可能是其他类型的，例如是int类型而不是int64，可以通过字符串来转换：</p>
<pre class="language-go"><code>func (this *MainController) Post() {
    id := this.Input().Get( "id" )
    intid, err := strconv.Atoi(id)
}</code></pre>
<p>&nbsp;</p>
<h2>1.2 绑定到结构体</h2>
<p>如果想把表单里的内容解析到一个结构体，beego提供了一种方式来绑定结构体，我们需要在定义requesParam结构体时使用 form字段打标签</p>
<pre class="language-go"><code>type user struct {
	Id    int         `form:"-"`
	Name  interface{} `form:"username"`
	Age   int         `form:"age"`
	Email string
}</code></pre>
<p>&nbsp;</p>
<p>html：</p>
<pre class="language-go"><code>名字：&lt; input name="username" type="text" /&gt;
年龄：&lt; input name="age" type="text" /&gt;
邮箱：&lt; input name="Email" type="text" /&gt;
&lt; input type="submit" value="提交" /&gt;</code></pre>
<p>&nbsp;</p>
<p>解析绑定参数：</p>
<pre class="language-go"><code>func (this *MainController) Post() {
    u := user{}
    if err := this.ParseForm(&amp;u); err != nil {
        //handle error
    }
}</code></pre>
<p>&nbsp;</p>
<p>注意：</p>
<ul>
<li>StructTag form 的定义和&nbsp;<a href="https://beego.vip/docs/mvc/view/view.md">renderform方法</a>&nbsp;共用一个标签</li>
<li>定义 struct 时，字段名后如果有 form 这个 tag，则会以把 form 表单里的 name 和 tag 的名称一样的字段赋值给这个字段，否则就会把 form 表单里与字段名一样的表单内容赋值给这个字段。如上面例子中，会把表单中的 username 和 age 分别赋值给 user 里的 Name 和 Age 字段，而 Email 里的内容则会赋给 Email 这个字段。</li>
<li>调用 Controller ParseForm 这个方法的时候，传入的参数必须为一个 struct 的指针，否则对 struct 的赋值不会成功并返回&nbsp;<code>xx must be a struct pointer</code>&nbsp;的错误。</li>
<li>如果要忽略一个字段，有两种办法，一是：字段名小写开头，二是：<code>form</code>&nbsp;标签的值设置为&nbsp;<code>-</code></li>
</ul>
<p>&nbsp;</p>
<h2>1.3 获取RequestBody内容</h2>
<p>在API开发中，我们经常会用到JSON或者XML作为数据交互的格式，如何在beego中获取RequestBody中的JSON或XML的数据呢？</p>
<ol>
<li>在配置文件里设置 cpoyrequestbody = true</li>
<li>在Controller中</li>
</ol>
<pre class="language-go"><code>func (this *ObjectController) Post() {
	var ob models.Object
	var err error
	if err = json.Unmarshal(this.Ctx.Input.RequestBody, &amp;ob); err == nil {
		objectid := models.AddOne(ob)
		this.Data["json"] = "{\"ObjectId\":\"" + objectid + "\"}"
	} else {
		this.Data["json"] = err.Error()
	}
	this.ServeJSON()
}</code></pre>
<p>　　</p>
<h2>1.4 文件上传</h2>
<p>在文件上传时记得在form表单中增加属性：&nbsp;enctype="multipart/form-data"</p>
<p>上传的文件一般是放在系统的内存中，如果文件的大小过大可能会造成内存不足的问题，我们可以通过配置文件限制文件缓存大小，默认64M</p>
<pre class="language-go"><code>maxmemory = 1&lt;&lt;22</code></pre>
<p>&nbsp;</p>
<p>与此同时，beego提供了另一个参数，MaxUploadSize来限制最大上传文件大小，如果一次上传多个文件，那么这个限制就是这些文件合并在一起的大小</p>
<p>默认情况下，MaxMemory应该小于MaxUploadSize，这种情况下两个参数合并在一起的效果为：</p>
<ul>
<li>如果文件小于MaxMemory，直接由内存处理</li>
<li>如果文件介于MaxMemory 和&nbsp;MaxUploadSize，那么比MaxMemory 大的部分将放在临时目录</li>
<li>如果文件大小超过MaxUploadSize，返回413拒绝请求</li>
</ul>
<p>&nbsp;</p>
<p>beego提供了两个很方便的方法来处理上传文件：</p>
<pre class="language-go"><code>GetFile(key string) (multipart.File, *multipart.FileHeader, error)&nbsp;</code></pre>
<p>该方法主要用于用户读取表单中的文件名&nbsp;<code>the_file</code>，然后返回相应的信息，用户根据这些变量来处理文件上传：过滤、保存文件等</p>
<p>&nbsp;</p>
<pre class="language-go"><code>SaveToFile(fromfile, tofile string) error</code></pre>
<p>该方法是在 GetFile 的基础上实现了快速保存的功能<br />fromfile 是提交时候的 html 表单中的 name</p>
<p>&nbsp;</p>
<p>文件保存的例子如下：</p>
<pre class="language-go"><code>&lt; form enctype="multipart/form-data" method="post"&gt;
    &lt; input type="file" name="uploadname" /&gt;
    &lt; input type="submit"&gt;
&lt;/ form &gt;</code></pre>
<p>&nbsp;</p>
<pre class="language-go"><code>func (c *FormController) Post() {
    f, h, err := c.GetFile( "uploadname" )
    if err != nil {
        log.Fatal( "getfile err " , err)
    }
    defer f.Close()
    c.SaveToFile( "uploadname" ,  "static/upload/" + h.Filename)  // 保存位置在 static/upload, 没有文件夹要先创建
   
}</code></pre>
<p>　　</p>
<h2>1.5 数据绑定</h2>
<p>支持从用户请求中直接数据 bind 到指定的对象，例如请求地址如下</p>
<pre class="language-go"><code>?id=123&amp;isok=true&amp;ft=1.2&amp;ol[0]=1&amp;ol[1]=2&amp;ul[]=str&amp;ul[]=array&amp;user.Name=astaxie</code></pre>
<p>&nbsp;</p>
<pre class="language-go"><code>var id int
this.Ctx.Input.Bind(&amp;id,  "id" )&nbsp;  //id ==123

var isok bool
this.Ctx.Input.Bind(&amp;isok,  "isok" )&nbsp;  //isok ==true

var ft float64
this.Ctx.Input.Bind(&amp;ft,  "ft" )&nbsp;  //ft ==1.2

ol := make([]int, 0, 2)
this.Ctx.Input.Bind(&amp;ol,  "ol" )&nbsp;  //ol ==[1 2]

ul := make([]string, 0, 2)
this.Ctx.Input.Bind(&amp;ul,  "ul" )&nbsp;  //ul ==[str array]

user  struct {Name}
this.Ctx.Input.Bind(&amp;user,  "user" )&nbsp;  //user =={Name:"astaxie"}</code></pre>
<p>&nbsp;</p>
<h1>2. 过滤器</h1>
<p>beego支持自定义过滤器中间件，例如安全验证、强制跳转等</p>
<p>过滤器函数如下所示：</p>
<pre class="language-go"><code>web.InsertFilter(pattern string, pos int, filter FilterFunc, opts ...FilterOpt)</code></pre>
<p>&nbsp;</p>
<p>InsertFilter 函数的三个必填参数，一个可选参数</p>
<ul>
<ul>
<li>pattern 路由规则，可以根据一定的规则进行路由，如果你全匹配可以用&nbsp;<code>*</code></li>
<li>position 执行 Filter 的地方，五个固定参数如下，分别表示不同的执行过程<br />
<ul>
<li>BeforeStatic 静态地址之前</li>
<li>BeforeRouter 寻找路由之前</li>
<li>BeforeExec 找到路由之后，开始执行相应的 Controller 之前</li>
<li>AfterExec 执行完 Controller 逻辑之后执行的过滤器</li>
<li>FinishRouter 执行完逻辑之后执行的过滤器</li>
</ul>
</li>
<li>filter filter 函数 type FilterFunc func(*context.Context)</li>
<li>opts<br />
<ol>
<li>web.WithReturnOnOutput: 设置 returnOnOutput 的值(默认 true), 如果在进行到此过滤之前已经有输出，是否不再继续执行此过滤器,默认设置为如果前面已有输出(参数为true)，则不再执行此过滤器</li>
<li>web.WithResetParams: 是否重置 filters 的参数，默认是 false，因为在 filters 的 pattern 和本身的路由的 pattern 冲突的时候，可以把 filters 的参数重置，这样可以保证在后续的逻辑中获取到正确的参数，例如设置了&nbsp;<code>/api/*</code>&nbsp;的 filter，同时又设置了&nbsp;<code>/api/docs/*</code>&nbsp;的 router，那么在访问&nbsp;<code>/api/docs/swagger/abc.js</code>&nbsp;的时候，在执行 filters 的时候设置&nbsp;<code>:splat</code>&nbsp;参数为&nbsp;<code>docs/swagger/abc.js</code>，但是如果不清楚 filter 的这个路由参数，就会在执行路由逻辑的时候保持&nbsp;<code>docs/swagger/abc.js</code>，如果设置了 true，就会重置&nbsp;<code>:splat</code>&nbsp;参数.</li>
<li>web.WithCaseSensitive: 是否大小写敏感。</li>
</ol>
</li>
</ul>
</ul>
<p>&nbsp;</p>
<p>例如下面的例子，验证用户是否已经登录，应用于全部的请求：</p>
<p>需要注意的是使用 session 的filter必须在 BeforeStatic之后才能获取，因为session没有在此之前初始化</p>
<pre class="language-go"><code>var FilterUser =  func (ctx *context.Context) {
    _, ok := ctx.Input.Session( "uid" ).(int)
    if !ok &amp;&amp; ctx.Request.RequestURI !=  "/login" {
        ctx.Redirect(302,  "/login" )
    }
}

web.InsertFilter( "/*" , web.BeforeRouter, FilterUser)</code></pre>
<p>&nbsp;</p>
<p>还可以通过正则路由进行过滤，如果参数匹配就执行：</p>
<pre class="language-go"><code>var FilterUser =  func (ctx *context.Context) {
    _, ok := ctx.Input.Session( "uid" ).(int)
    if !ok {
        ctx.Redirect(302,  "/login" )
    }
}
web.InsertFilter( "/user/:id([0-9]+)" , web.BeforeRouter, FilterUser)</code></pre>
<p>&nbsp;</p>
<h2>2.1 过滤器实现路由</h2>
<p>beego1.1.2 开始 Context.Input 中增加了 RunController 和 RunMethod，这样我们就可以在执行路由查找之前，在 filter 中实现自己的路由规则</p>
<p>如下实现了如何实现自己的路由规则：</p>
<pre class="language-go"><code>var UrlManager =  func (ctx *context.Context) {
    // 数据库读取全部的 url mapping 数据
    urlMapping := model.GetUrlMapping()
    for baseurl,rule:= range urlMapping {
        if baseurl == ctx.Request.RequestURI {
            ctx.Input.RunController = rule.controller
            ctx.Input.RunMethod = rule.method
            break
        }
    }
}

web.InsertFilter( "/*" , web.BeforeRouter, web.UrlManager)</code></pre>
<p>&nbsp;</p>
<h2>2.2 Filter和FilterChain</h2>
<p>实现在一个Filter中调用另一个Filter，支持Filter-Chain的设计模式：</p>
<pre class="language-go"><code>type FilterChain  func (next FilterFunc) FilterFunc</code></pre>
<p>&nbsp;</p>
<p>例如一个非常简单的例子：</p>
<pre class="language-go"><code>package main

import (
    "github.com/beego/beego/v2/core/logs"
    "github.com/beego/beego/v2/server/web"
    "github.com/beego/beego/v2/server/web/context"
)

func main() {
    web.InsertFilterChain( "/*" ,  func (next web.FilterFunc) web.FilterFunc {
        return func (ctx *context.Context) {
            // do something
            logs.Info( "hello" )
            // don't forget this
            next(ctx)

            // do something
        }
    })
}</code></pre>
<p>&nbsp;</p>
<p>在这个例子里面，只是输出了一句 hello，就调用了下一个Filter</p>
<p>在执行完next(ctx)之后，实际上，如果后面的Filter没有中断整个流程，那么这时候Output对象已经被复制了，意味着能够拿到响应码等数据</p>
<p>&nbsp;</p>
<h1>3. XSRF过滤</h1>
<p><a href="http://en.wikipedia.org/wiki/Cross-site_request_forgery">跨站请求伪造(Cross-site request forgery)</a>， 简称为 XSRF，是 Web 应用中常见的一个安全问题。前面的链接也详细讲述了 XSRF 攻击的实现方式</p>
<p>当前防范 XSRF 的一种通用的方法，是对每一个用户都记录一个无法预知的 cookie 数据，然后要求所有提交的请求（POST/PUT/DELETE）中都必须带有这个 cookie 数据。如果此数据不匹配 ，那么这个请求就可能是被伪造的</p>
<p>&nbsp;</p>
<h2>3.1 全局屏蔽</h2>
<p>beego 有内建的 XSRF 的防范机制，要使用此机制，你需要在应用配置文件中加上&nbsp;<code>enablexsrf</code>&nbsp;设定</p>
<pre class="language-go"><code>enablexsrf = true
xsrfkey = 61oETzKXQAGaYdkL5gEmGeJJFuYh7EQnp2XdTP1o
xsrfexpire = 3600</code></pre>
<p>&nbsp;</p>
<p>或者在main入口这样设置：</p>
<pre class="language-go"><code>web.EnableXSRF = true
web.XSRFKEY =  "61oETzKXQAGaYdkL5gEmGeJJFuYh7EQnp2XdTP1o"
web.XSRFExpire = 3600&nbsp;  //过期时间，默认1小时</code></pre>
<p>&nbsp;</p>
<p>如果开启了&nbsp;XSRF，那么 beego 的 Web 应用将对所有用户设置一个&nbsp;<code>_xsrf</code>&nbsp;的 cookie 值（默认过期 1 小时）</p>
<p>如果&nbsp;<code>POST PUT DELET</code>&nbsp;请求中没有这个 cookie 值，那么这个请求会被直接拒绝</p>
<p>如果你开启了这个机制，那么在所有被提交的表单中，你都需要加上一个域来提供这个值，你可以通过在模板中使用 专门的函数&nbsp;<code>XSRFFormHTML()</code>&nbsp;来做到这一点</p>
<p>过期时间上面我们设置了全局的过期时间&nbsp;<code>web.XSRFExpire</code>，但是有些时候我们也可以在控制器中修改这个过期时间，专门针对某一类处理逻辑：</p>
<pre class="language-go"><code>func (this *HomeController) Get(){
    this.XSRFExpire = 7200
    this.Data[ "xsrfdata" ]=template.HTML(this.XSRFFormHTML())
}</code></pre>
<p>&nbsp;</p>
<p>在 Beego 2.x 里面有一个很大的不同，就是 Beego 2.x 的XSRF只支持 HTTPS 协议。</p>
<p>这是因为，在 2.x 的时候，我们给存储 XSRF token的 cookie 加上了&nbsp;<a href="https://en.wikipedia.org/wiki/Secure_cookie">secure</a>,&nbsp;<a href="https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies">http-only</a>.<br />两个设置，所以只能通过 HTTPS 协议运作。</p>
<p>与此同时，你也无法通过 JS 获取到 XSRF token。</p>
<p>这个改进，一个很重要的原因是，在 1.x 的时候，缺乏这两个选项，会导致攻击者可以从 cookie 中拿到 XSRF token，导致 XSRF 失效</p>
<p>&nbsp;</p>
<h2>3.2 Controller级别的过滤</h2>
<p>XSRF 之前是全局设置的一个参数，如果设置了那么所有的 API 请求都会进行验证，但是有些时候API 逻辑是不需要进行验证的，因此现在支持在controller 级别设置屏蔽：</p>
<pre class="language-go"><code>type AdminController  struct {
    web.Controller
}

func (a *AdminController) Prepare() {
    a.EnableXSRF = false
}</code></pre>
<p>&nbsp;</p>
<p>　　</p>