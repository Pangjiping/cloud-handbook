<h1>1. 多种格式输出</h1>
<p>struct属性应该为可导出的，首字母大写</p>
<h2>1.1 JSON格式输出</h2>
<p>在调用<code>ServeJSON</code>之后，会设置<code>content-type</code>为<code>application/json</code>，然后同时把数据进行JSON序列化输出</p>
<pre class="language-go"><code>func (c *MainController) Get() {
	mystruct := {...}
	c.Data["json"]=&amp;mystruct
	c.ServeJSON()
}</code></pre>
<p>&nbsp;</p>
<h2>1.2 XML格式输出</h2>
<p>在调用<code>ServeXML</code>之后，会设置<code>content-type</code>为<code>application/xml</code>，同时数据会进行XML序列化输出</p>
<pre class="language-go"><code>func (c *MainController) Get() {
	mystruct := {...}
	c.Data["xml"]=&amp;mystruct
	c.ServeXML()
}</code></pre>
<p>&nbsp;</p>
<h2>1.3 jsonp调用</h2>
<p>调用<code>ServeJSONP</code>之后，会设置<code>content-type</code>为<code>application/javascript</code>，然后同时把数据进行JSON序列化，根据请求的callback参数设置jsonp输出</p>
<pre class="language-go"><code>func (c *MainController) Get() {
	mystruct := {...}
	c.Data["jsonp"]=&amp;mystruct
	c.ServeJSONP()
}</code></pre>
<p>&nbsp;</p>
<h1>2. URL构建</h1>
<h2>2.1 URLFor()</h2>
<p><code>URLFor()</code>函数就是用于构建指定函数的URL</p>
<p>它把对应控制器的函数名结合字符串作为第一个参数，其余参数对应URL中的变量，位置变量添加到URL中作为查询参数</p>
<p>下面定义了一个相应的控制器：</p>
<pre class="language-go"><code>type TestController struct {
	beego.Controller
}

func (t *TestController) Get() {
	t.Data["Username"] = "astaxie"
	t.Ctx.Output.Body([]byte("ok"))
}
func (t *TestController) List() {
	t.Ctx.Output.Body([]byte("i am list"))
}
func (t *TestController) Params() {
	t.Ctx.Output.Body([]byte(t.Ctx.Input.Params()["0"] +
		t.Ctx.Input.Params()["1"] +
		t.Ctx.Input.Params()["2"]))
}
func (t *TestController) Myext() {
	t.Ctx.Output.Body([]byte(t.Ctx.Input.Param(":ext")))
}
func (t *TestController) GetUrl() {
	t.Ctx.Output.Body([]byte(t.URLFor(".Myext")))
}</code></pre>
<p>&nbsp;</p>
<p>下面是我们注册的路由：</p>
<pre class="language-go"><code>beego.Router("/api/list", &amp;TestController{}, "*:List")
beego.Router("/person/:last/:first", &amp;TestController{})
beego.AutoRouter(&amp;TestController{})</code></pre>
<p>&nbsp;</p>
<p>那么通过<code>URLFor()</code>可以获取相应的URL地址</p>
<pre class="language-go"><code>beego.URLFor("TestController.List")
// 输出 /api/list

beego.URLFor("TestController.Get", ":last", "xie", ":first", "asta")
// 输出 /person/xie/asta

beego.URLFor("TestController.Myext")
// 输出 /Test/Myext

beego.URLFor("TestController.GetUrl")
// 输出 /Test/GetUrl</code></pre>
<p>&nbsp;</p>
<h2>2.2 在模板中构建URL</h2>
<p>默认情况下，beego已经注册了<code>URLFor()</code>函数，用户可以通过如下代码进行调用</p>
<pre class="language-html"><code>{{urlfor "TestController.List"}}</code></pre>
<p>&nbsp;</p>
<p>为什么把URL写死在模板中，反而要动态构建？有两个理由：</p>
<ul>
<li>反向解析通常比硬编码URL更直观，同时更重要的是可以只在一个地方改变URL，而不用带出乱找</li>
<li>URL创建会处理特殊字符的转义和unicode数据</li>
</ul>
<p>&nbsp;</p>
<h1>3. flash数据</h1>
<p>flash数据主要用于在两个逻辑之间传递临时数据，flash中存放的所有数据会在紧接着的下一个逻辑调用后删除</p>
<p>flash数据一般用于传递提示和错误消息，它适合POST/REDIRECT/GET模式</p>
<pre class="language-go"><code>// Get 显示设置信息
func (c *MainController) Get() {
	flash := beego.ReadFromRequest(&amp;c.Controller)
	if n, ok := flash.Data["notice"]; ok {
		// 显示设置成功
		c.TplName = "set_success.html"
	} else if n, ok = flash.Data["error"]; ok {
		// 显示错误
		c.TplName = "set_error.html"
	} else {
		// 显示默认页面
		c.Data["list"] = GetInfo()
		c.TplName = "setting_list.html"
	}
}

// Post 处理设置信息
func (c *MainController) Post() {
	flash := beego.NewFlash()
	setting := Settings{}
	valid := Validation{}
	c.ParseForm(*setting)
	if b, err := valid.Valid(setting); err != nil {
		flash.Error("Setting invalid")
		flash.Store(&amp;c.Controller)
		c.Redirect("/setting", 302)
	} else if b != nil {
		flash.Error("validation error")
		flash.Store(&amp;c.Controller)
		c.Redirect("/setting", 302)
		return
	}

	saveSetting(setting)
	flash.Notice("Setting saved")
	flash.Store(&amp;c.Controller)
	c.Redirect("/setting", 302)
}</code></pre>
<p>&nbsp;</p>
<p>上面的代码执行逻辑大概是这样的：</p>
<ul>
<li><code>Get()</code>方法执行，因为没有flash数据，所以显示设置界面</li>
<li>用户设置信息之后点击提交，执行<code>Post()</code>，然后初始化一个flash，通过验证，验证出错或者验证不通过设置flash的error信息，如果通过了保存设置，设置flash的notice信息</li>
<li>设置完成后跳转到GET请求</li>
<li>GET请求获取到了falsh信息，然后执行相应的逻辑，如果出错显示出错的页面，如果成功显示成功页面</li>
</ul>
<p>默认情况下<code>ReadFromRequest()</code>函数已经实现了读取的数据赋值给flash，所以在模板中可以这样读取数据：</p>
<pre class="language-html"><code>{{.flash.error}}
{{.flash.warning}}
{{.flash.notice}}</code></pre>
<p>&nbsp;</p>
<p>flash对象有三个级别的设置：</p>
<ul>
<li>Notice 提示信息</li>
<li>Warning 警告信息</li>
<li>Error 错误信息</li>
</ul>
<p>&nbsp;</p>