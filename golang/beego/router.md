<h1>1. beego参数配置</h1>
<p>beego目前支持INI、XML、JSON、YAML格式的配置文件解析，但是默认采用了INI格式解析，用户可以通过简单的配置就可以获得很大的灵活性</p>
<p>&nbsp;</p>
<h2>1.1 默认配置解析</h2>
<p>neego会默认解析当前应用下的 conf/app.conf 文件</p>
<p>当我们使用 bee new 命令新建一个项目时，app.conf 文件默认参数只有以下几个：</p>
<pre class="language-go"><code>appname = pro01  // appname随便改
httpport = 8080  // 服务端口
runmode = dev  // 开发模式</code></pre>
<p>&nbsp;</p>
<p>这里面可写的参数不是任意的，都会被维护在结构体 beego/server/web#Config 中</p>
<p>beego的参数主要包含了以下这些&nbsp;<a href="https://godoc.org/github.com/beego/beego#pkg-constants">https://godoc.org/github.com/beego/beego#pkg-constants</a></p>
<p>&nbsp;</p>
<p>可以在配置文件中配置应用需要的配置信息，比如mysql的连接信息</p>
<pre class="language-go"><code>mysqluser =  "root"
mysqlpass =  "rootpass"</code></pre>
<p>&nbsp;</p>
<p>需要这些配置信息时，只需要使用AppConfig的一系列方法就可以取到数据</p>
<pre class="language-go"><code>user,err := beego.AppConfig.String( "mysqluser" )</code></pre>
<p>&nbsp;</p>
<p>AppConfig支持的方法如下：</p>
<pre class="language-go"><code>Set(key, val string) error
String(key string) string
Strings(key string) []string
Int(key string) (int, error)
Int64(key string) (int64, error)
Bool(key string) (bool, error)
Float(key string) (float64, error)
DefaultString(key string, defaultVal string) string
DefaultStrings(key string, defaultVal []string)
DefaultInt(key string, defaultVal int) int
DefaultInt64(key string, defaultVal int64) int64
DefaultBool(key string, defaultVal bool) bool
DefaultFloat(key string, defaultVal float64) float64
DIY(key string) ( interface {}, error)
GetSection(section string) ( map [string]string, error)
SaveConfigFile(filename string) error</code></pre>
<p>&nbsp;</p>
<h2>1.2 不同级别的配置</h2>
<p>在配置文件中里面支持section，可以有不同的 Runmode 的配置，默认优先读取 runmode 下的配置信息，例如下面的配置文件：</p>
<pre class="language-go"><code>appname = beepkg
httpport = 9090
runmode = "dev"

[dev]
httpport = 8080
[prod]
httpport = 8088
[test]
httpport = 8888</code></pre>
<p>　　</p>
<p>上面的配置文件就是在不同 runmode 下解析不同的配置</p>
<p>在dev模式下，服务端口是8080，在prod模式下是8088</p>
<p>读取不同模式下配置参数的方法是 模式::配置参数名 ，比如：</p>
<pre class="language-go"><code>beego.AppConfig.String( "dev::mysqluser" )</code></pre>
<p>&nbsp;</p>
<h2>1.3 多个配置文件</h2>
<p>INI格式支持include方式引用多个配置文件例如下面的例子</p>
<p>app.conf</p>
<pre class="language-go"><code>appname = pro01
httpport = 8080
runmode = dev

include  "app2.conf"</code></pre>
<p>&nbsp;</p>
<p>app2.conf</p>
<pre class="language-go"><code>runmode = "dev"
autorender = false
recoverpanic = false
viewspath =  "myview"

[dev]
httpport = 8080
[prod]
httpport = 8088
[test]
httpport = 8888</code></pre>
<p>　　</p>
<h2>1.4 支持环境变量配置</h2>
<p>配置文件解析支持从环境变量中获取配置，配置项格式 <span style="color: #ff0000;">${环境变量}</span></p>
<p>例如下面的配置中优先使用环境变量中配置的 runmode 和 httpport</p>
<p>如果有配置环境变量 ProRunMode 则优先使用该环境变量值；如果不存在或者为空，则使用 &ldquo;dev&rdquo; 作为 runmode</p>
<pre class="language-go"><code>runmode&nbsp; =  "${ProRunMode||dev}"
httpport =  "${ProPort||9090}"</code></pre>
<p>　　</p>
<h2>1.5 系统默认参数</h2>
<p><a href="https://beego.vip/docs/mvc/controller/config.md">参数配置 - beego: 简约 &amp; 强大并存的 Go 应用框架</a></p>
<p>&nbsp;</p>
<h1>2. beego路由设置</h1>
<p>beego路由存在三种方式：固定路由、正则路由、自动路由</p>
<p>&nbsp;</p>
<h2>2.1 固定路由</h2>
<p>固定路由是最常见的路由方式，一个固定的路由地址加一个控制器模式</p>
<p>固定路由示例如下所示：</p>
<pre class="language-go"><code>beego.Router( "/" , &amp;controllers.MainController{})
beego.Router( "/admin" , &amp;admin.UserController{})
beego.Router( "/admin/index" , &amp;admin.ArticleController{})
beego.Router( "/admin/addpkg" , &amp;admin.AddController{})</code></pre>
<p>&nbsp;</p>
<h2>2.2 正则路由</h2>
<p>形如下面这种路由设置</p>
<div class="cnblogs_code">
<pre>http:<span style="color: #008000;">//</span><span style="color: #008000;">localhost:8080/api/?:id</span>
http:<span style="color: #008000;">//</span><span style="color: #008000;">localhost:8080/api/:id</span></pre>
</div>
<p>&nbsp;</p>
<p>这两个路由的默认匹配都是 /api/123类型的，但是第一个路由 /api/可以正常匹配，第二个就会匹配失败</p>
<p>可以在Controller中通过如下方式获取上面的变量，记得添加冒号！</p>
<pre class="language-go"><code>c.Ctx.Input.Param(":id")</code></pre>
<p>&nbsp;</p>
<h2>2.3 自动路由</h2>
<p>自动路由需要先把需要路由的控制器注册到自动路由中</p>
<pre class="language-go"><code>beego.AutoRouter(&amp;controllers.ObjectController{})</code></pre>
<p>&nbsp;</p>
<p>那么beego就会通过反射来获取该结构体的所有实现方法，就可以通过下面的方式访问到对应的方法</p>
<p>两个前缀分别为controller的名字和方法名 /:controller/:method</p>
<pre class="language-go"><code>/object/login&nbsp;&nbsp; 调用 ObjectController 中的 Login 方法
/object/logout&nbsp; 调用 ObjectController 中的 Logout 方法</code></pre>
<p>&nbsp;</p>
<p>除了两个前缀的匹配外，剩下的 URL beego会自动解析为参数，保存在 this.Ctx.Input.Params中</p>
<pre class="language-go"><code>/object/blog/2013/09/12&nbsp; 调用 ObjectController 中的 Blog 方法，参数如下： map [0:2013 1:09 2:12]</code></pre>
<p>&nbsp;</p>
<p>现在已经可以通过自动识别出来下面类似的所有 url，都会把请求分发到&nbsp;<code>controller</code>&nbsp;的&nbsp;<code>simple</code>&nbsp;方法</p>
<p>后缀名可以通过 this.Ctx.Input.Param(":ext") 来获取</p>
<pre class="language-go"><code>/controller/simple
/controller/simple.html
/controller/simple.json
/controller/simple.xml</code></pre>
<p>&nbsp;</p>
<h2>2.4 自定义方法和RESTful规则</h2>
<p>如果用户期望使用自定义函数名，那么可以使用如下方式：</p>
<pre class="language-go"><code>beego.Router( "/" ,&amp;IndexController{}, "*:Index" )</code></pre>
<p>&nbsp;</p>
<p>使用第三个参数，第三个参数就是用来设置对应method到函数名，定义如下：</p>
<ul>
<li>* 表示任意的method都执行该函数</li>
<li>使用httpmethod:funcname格式来展示</li>
<li>多个不同的格式使用 ; 分隔</li>
<li>多个method对应同一个funcname，method之间采用 , 分隔</li>
</ul>
<p>比如下面的例子中，我们要为同一个URL针对不同类型的请求，绑定不同的控制器</p>
<pre class="language-go"><code>beego.Router( "/api/food" ,&amp;RestController{}, "get:ListFood" )
beego.Router( "/api/food" ,&amp;RestController{}, "post:CreateFood" )
beego.Router( "/api/food" ,&amp;RestController{}, "put:UpdateFood" )
beego.Router( "/api/food" ,&amp;RestController{}, "delete:DeleteFood" )</code></pre>
<p>&nbsp;</p>
<p>在使用时不推荐采用 ；分隔的方式来加入多个method:func，会使得代码可读性不强</p>
<p>在绑定时支持的http方法包含以下几类，都要小写就行</p>
<ul>
<li>* 所有请求</li>
<li>GET</li>
<li>POST</li>
<li>PUT</li>
<li>DELETE</li>
<li>PATCH</li>
<li>OPTIONS</li>
<li>HEAD</li>
</ul>
<p>如果同时存在 * 和具体的HTTP方法对应的函数，那么优先执行HTTP方法对应的函数</p>
<p>&nbsp;</p>
<h2>2.5 namespace</h2>
<p>namespace就是需要优先解析的一个URL参数</p>
<p>比如在下面这个例子中，通过NewNamespace方法定义了一个 /v1 namespace</p>
<p>在namesapce中首先通过NSCond()方法来判断是不是满足该 namespace的执行条件</p>
<p>然后后续通过NS+HTTP method格式的方法绑定了很多控制器</p>
<p>最后通过 beego.AddNamespace(ns) 将这个namesapce注册到路由中</p>
<pre class="language-go"><code>//初始化 namespace
ns :=
web.NewNamespace( "/v1" ,
    web.NSCond( func (ctx *context.Context) bool {
        if ctx.Input.Domain() ==  "api.beego.vip" {
            return true
        }
        return false
    }),
    web.NSBefore(auth),
    web.NSGet( "/notallowed" ,  func (ctx *context.Context) {
        ctx.Output.Body([]byte( "notAllowed" ))
    }),
    web.NSRouter( "/version" , &amp;AdminController{},  "get:ShowAPIVersion" ),
    web.NSRouter( "/changepassword" , &amp;UserController{}),
    web.NSNamespace( "/shop" ,
        web.NSBefore(sentry),
        web.NSGet( "/:id" ,  func (ctx *context.Context) {
            ctx.Output.Body([]byte( "notAllowed" ))
        }),
    ),
    web.NSNamespace( "/cms" ,
        web.NSInclude(
            &amp;controllers.MainController{},
            &amp;controllers.CMSController{},
            &amp;controllers.BlockController{},
        ),
    ),
)
//注册 namespace
web.AddNamespace(ns)</code></pre>
<p>&nbsp;</p>
<p>上面这个代码支持了如下的URL请求：</p>
<ul>
<li>GET /v1/notallowed</li>
<li>GET /v1/version</li>
<li>GET /v1/changepassword</li>
<li>POST /v1/changepassword</li>
<li>GET /v1/shop/123</li>
<li>GET /v1/cms/ 对应 MainController、CMSController、BlockController 中的注解路由</li>
</ul>
<p>&nbsp;</p>
<h1>3. beego控制器</h1>
<p>自定义controller的实现需要继承beego.Controller</p>
<pre class="language-go"><code>package controllers

import beego  "github.com/beego/beego/v2/server/web"

type UserController  struct {
    beego.Controller
}</code></pre>
<p>&nbsp;</p>
<h2>3.1 控制器方法</h2>
<p>beego.Controller实现了接口 beego.ControllerInterface，主要包含了以下函数</p>
<pre class="language-go"><code>type ControllerInterface  interface {
    Init(ct *context.Context, controllerName, actionName string, app  interface {})
    Prepare()
    Get()
    Post()
    Delete()
    Put()
    Head()
    Patch()
    Options()
    Trace()
    Finish()
    Render() error
    XSRFToken() string
    CheckXSRFCookie() bool
    HandlerFunc(fn string) bool
    URLMapping()
}</code></pre>
<ul>
<li>Init()：初始化context、Controller名称、模板名等</li>
<li>Prepare()：用户扩展，这个函数会在下面定义的这些Method方法之前执行，用户可以重写这个函数实现类似于用户验证的工作</li>
<li>Finish()：这个函数是在执行完HTTP method之后执行，默认为nil，用户可以重写这个函数用于关闭数据库、清理缓存等工作</li>
<li>Render()：这个函数主要用来实现渲染模板，如果 beego.AutoRender 为 true 的情况下才会执行</li>
</ul>
<p>&nbsp;</p>
<h2>3.2 子类扩展</h2>
<p>通过子类对于方法的重写，用户可以实现自己的逻辑，下面是一个实际的例子</p>
<pre class="language-go"><code>type AddController  struct {
    web.Controller
}

func (this *AddController) Prepare() {

}

// Get 渲染一个模板
func (this *AddController) Get() {
    this.Data[ "content" ] =  "value"
    this.Layout =  "admin/layout.html"
    this.TplName =  "admin/add.tpl"
}

func (this *AddController) Post() {
    pkgname := this.GetString( "pkgname" )
    content := this.GetString( "content" )
    pk := models.GetCruPkg(pkgname)
    if pk.Id == 0 {
        var pp models.PkgEntity
        pp.Pid = 0
        pp.Pathname = pkgname
        pp.Intro = pkgname
        models.InsertPkg(pp)
        pk = models.GetCruPkg(pkgname)
    }
    var at models.Article
    at.Pkgid = pk.Id
    at.Content = content
    models.InsertArticle(at)
    this.Ctx.Redirect(302,  "/admin/index" )
}</code></pre>
<p>&nbsp;</p>
<p>下面是一个比较流行的架构，首先实现一个自己的基类 baseController，实现以下初始化的方法，然后其他所有逻辑继承自该基类</p>
<pre class="language-go"><code>type NestPreparer  interface {
        NestPrepare()
}

// baseRouter implemented global settings for all other routers.
type baseController  struct {
        web.Controller
        i18n.Locale
        user&nbsp;&nbsp;&nbsp; models.User
        isLogin bool
}
// Prepare implemented Prepare method for baseRouter.
func (this *baseController) Prepare() {

        // page start time
        this.Data[ "PageStartTime" ] = time.Now()

        // Setting properties.
        this.Data[ "AppDescription" ] = utils.AppDescription
        this.Data[ "AppKeywords" ] = utils.AppKeywords
        this.Data[ "AppName" ] = utils.AppName
        this.Data[ "AppVer" ] = utils.AppVer
        this.Data[ "AppUrl" ] = utils.AppUrl
        this.Data[ "AppLogo" ] = utils.AppLogo
        this.Data[ "AvatarURL" ] = utils.AvatarURL
        this.Data[ "IsProMode" ] = utils.IsProMode

        if app, ok := this.AppController.(NestPreparer); ok {
                app.NestPrepare()
        }
}</code></pre>
<p>&nbsp;</p>
<p>上面定义了基类，大概是初始化了一些变量，最后有一个 Init() 函数中的那个 app 的应用</p>
<p>判断当前运行的Controller是否是NestPreparer的实现，如果是的话调用子类的方法，下面是NestPreparer的实现：</p>
<pre class="language-go"><code>type BaseAdminRouter  struct {
    baseController
}

func (this *BaseAdminRouter) NestPrepare() {
    if this.CheckActiveRedirect() {
            return
    }

    // if user isn't admin, then logout user
    if !this.user.IsAdmin {
            models.LogoutUser(&amp;this.Controller)

            // write flash message
            this.FlashWrite( "NotPermit" ,  "true" )

            this.Redirect( "/login" , 302)
            return
    }

    // current in admin page
    this.Data[ "IsAdmin" ] = true

    if app, ok := this.AppController.(ModelPreparer); ok {
            app.ModelPrepare()
            return
    }
}

func (this *BaseAdminRouter) Get(){
    this.TplName =  "Get.tpl"
}

func (this *BaseAdminRouter) Post(){
    this.TplName =  "Post.tpl"
}</code></pre>
<p>&nbsp;</p>
<p>这样我们的执行器执行的逻辑是这样的，首先执行 Prepare，这个就是 Go 语言中 struct 中寻找方法的顺序，依次往父类寻找。</p>
<p>执行&nbsp;<code>BaseAdminRouter</code>&nbsp;时，查找他是否有&nbsp;<code>Prepare</code>&nbsp;方法，没有就寻找&nbsp;<code>baseController</code>，找到了，那么就执行逻辑，</p>
<p>然后在&nbsp;<code>baseController</code>&nbsp;里面的&nbsp;<code>this.AppController</code>&nbsp;即为当前执行的控制器&nbsp;<code>BaseAdminRouter</code>，因为会执行&nbsp;<code>BaseAdminRouter.NestPrepare</code>&nbsp;方法。</p>
<p>然后开始执行相应的 Get 方法或者 Post 方法</p>
<p>&nbsp;</p>
<h2>3.3 提前终止运行</h2>
<p>我们应用中经常会遇到这种情况，在Prepare阶段进行判断，如果用户认证不通过，则输出一段提示信息然后终止进程</p>
<p>可以使用StopRun来终止执行逻辑，可以在任意地方执行</p>
<pre class="language-go"><code>type RController  struct {
    beego.Controller
}

func (this *RController) Prepare() {
    this.Data[ "json" ] =  map [string] interface {}{ "name" :  "astaxie" }
    this.ServeJSON()
    this.StopRun()
}</code></pre>
<p>　　</p>
<p>在调用StopRun()之后，如果还定义了Finish()，那么Finish()不会执行，如果需要释放资源，需要在StopRun()之前手动调用Finish()</p>
<p>&nbsp;</p>