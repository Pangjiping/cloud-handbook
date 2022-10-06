<h1>1. 表单数据验证</h1>
<p>首先需要安装依赖：</p>
<pre class="language-bash"><code>go get github.com/beego/beego/v2/core/validation</code></pre>
<p>&nbsp;</p>
<p>表单数据验证是用于数据验证和错误收集的模块</p>
<p>示例：</p>
<pre class="language-go"><code>type User struct {
	Name string
	Age  int
}

func main() {
	u := User{"man", 40}
	valid := validation.Validation{}
	valid.Required(u.Name, "name")
	valid.MaxSize(u.Name, 15, "nameMax")
	valid.Range(u.Age, 0, 18, "age")

	// 如果有错误信息，证明验证未通过
	// 打印错误信息
	if valid.HasErrors() {
		for _, err := range valid.Errors {
			log.Println(err.Key, err.Message)
		}
	}

	// or use like this
	if v := valid.Max(u.Age, 140, "age"); !v.Ok {
		log.Println(v.Error.Key, v.Error.Message)
	}

	// 定制错误信息
	minAge := 18
	valid.Min(u.Age, minAge, "age").Message("少儿不宜！")
	valid.Min(u.Age, minAge, "age").Message("%d不禁", minAge)
}</code></pre>
<p>&nbsp;</p>
<p>通过StructTag使用示例：</p>
<pre class="language-go"><code>// 验证函数写在 "valid" tag 的标签里
// 各个函数之间用分号 ";" 分隔，分号后面可以有空格
// 参数用括号 "()" 括起来，多个参数之间用逗号 "," 分开，逗号后面可以有空格
// 正则函数(Match)的匹配模式用两斜杠 "/" 括起来
// 各个函数的结果的 key 值为字段名.验证函数名
type user struct {
    Id     int
    Name   string `valid:"Required;Match(/^Bee.*/)"` // Name 不能为空并且以 Bee 开头
    Age    int    `valid:"Range(1, 140)"` // 1 &lt;= Age &lt;= 140，超出此范围即为不合法
    Email  string `valid:"Email; MaxSize(100)"` // Email 字段需要符合邮箱格式，并且最大长度不能大于 100 个字符
    Mobile string `valid:"Mobile"` // Mobile 必须为正确的手机号
    IP     string `valid:"IP"` // IP 必须为一个正确的 IPv4 地址
}

// 如果你的 struct 实现了接口 validation.ValidFormer
// 当 StructTag 中的测试都成功时，将会执行 Valid 函数进行自定义验证
func (u *user) Valid(v *validation.Validation) {
    if strings.Index(u.Name, "admin") != -1 {
        // 通过 SetError 设置 Name 的错误信息，HasErrors 将会返回 true
        v.SetError("Name", "名称里不能含有 admin")
    }
}

func main() {
    valid := validation.Validation{}
    u := user{Name: "Beego", Age: 2, Email: "dev@web.me"}
    b, err := valid.Valid(&amp;u)
    if err != nil {
        // handle error
    }
    if !b {
        // validation does not pass
        // blabla...
        for _, err := range valid.Errors {
            log.Println(err.Key, err.Message)
        }
    }
}</code></pre>
<p>&nbsp;</p>
<p>StructTag可用的验证函数：</p>
<ul>
<li><code>Required</code>&nbsp;不为空，即各个类型要求不为其零值</li>
<li><code>Min(min int)</code>&nbsp;最小值，有效类型：<code>int</code>，其他类型都将不能通过验证</li>
<li><code>Max(max int)</code>&nbsp;最大值，有效类型：<code>int</code>，其他类型都将不能通过验证</li>
<li><code>Range(min, max int)</code>&nbsp;数值的范围，有效类型：<code>int</code>，他类型都将不能通过验证</li>
<li><code>MinSize(min int)</code>&nbsp;最小长度，有效类型：<code>string slice</code>，其他类型都将不能通过验证</li>
<li><code>MaxSize(max int)</code>&nbsp;最大长度，有效类型：<code>string slice</code>，其他类型都将不能通过验证</li>
<li><code>Length(length int)</code>&nbsp;指定长度，有效类型：<code>string slice</code>，其他类型都将不能通过验证</li>
<li><code>Alpha</code>&nbsp;alpha字符，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Numeric</code>&nbsp;数字，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>AlphaNumeric</code>&nbsp;alpha 字符或数字，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Match(pattern string)</code>&nbsp;正则匹配，有效类型：<code>string</code>，其他类型都将被转成字符串再匹配(fmt.Sprintf(&ldquo;%v&rdquo;, obj).Match)</li>
<li><code>AlphaDash</code>&nbsp;alpha 字符或数字或横杠&nbsp;<code>-_</code>，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Email</code>&nbsp;邮箱格式，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>IP</code>&nbsp;IP 格式，目前只支持 IPv4 格式验证，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Base64</code>&nbsp;base64 编码，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Mobile</code>&nbsp;手机号，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Tel</code>&nbsp;固定电话号，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>Phone</code>&nbsp;手机号或固定电话号，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
<li><code>ZipCode</code>&nbsp;邮政编码，有效类型：<code>string</code>，其他类型都将不能通过验证</li>
</ul>
<p>&nbsp;</p>
<p>自定义验证</p>
<p>允许自己注册验证逻辑，使用方法：</p>
<pre class="language-go"><code>AddCustomFunc(name string, f CustomFunc) error</code></pre>
<p>&nbsp;</p>
<p>注意的是，该方法并不是线程安全的。在我们的设计理念中，注册这种自定义的方法，应该在系统初始化阶段完成。在该阶段，应当不存在竞争问题</p>
<p>&nbsp;</p>
<h1>2. 错误处理</h1>
<p>我们在做 Web 开发的时候，经常需要页面跳转和错误处理，beego 这方面也进行了考虑，通过&nbsp;<code>Redirect</code>&nbsp;方法来进行跳转：</p>
<pre class="language-go"><code>func (this *AddController) Get() {
    this.Redirect("/", 302)
}</code></pre>
<p>&nbsp;</p>
<p>如何中止此次请求并抛出异常，beego 可以在控制器中这样操作：</p>
<pre class="language-go"><code>func (this *MainController) Get() {
    this.Abort("401")
    v := this.GetSession("asta")
    if v == nil {
        this.SetSession("asta", int(1))
        this.Data["Email"] = 0
    } else {
        this.SetSession("asta", v.(int)+1)
        this.Data["Email"] = v.(int)
    }
    this.TplName = "index.tpl"
}</code></pre>
<p>&nbsp;</p>
<p>这样&nbsp;<code>this.Abort("401")</code>&nbsp;之后的代码不会再执行，而且会默认显示给用户如下页面：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220411153944734-2061286403.png" /></p>
<p>&nbsp;</p>
<p>web 框架默认支持 401、403、404、500、503 这几种错误的处理。用户可以自定义相应的错误处理，例如下面重新定义 404 页面：</p>
<pre class="language-go"><code>func page_not_found(rw http.ResponseWriter, r *http.Request){
    t,_:= template.New("404.html").ParseFiles(web.BConfig.WebConfig.ViewsPath+"/404.html")
    data :=make(map[string]interface{})
    data["content"] = "page not found"
    t.Execute(rw, data)
}

func main() {
    web.ErrorHandler("404",page_not_found)
    web.Router("/", &amp;controllers.MainController{})
    web.Run()
}</code></pre>
<p>&nbsp;</p>
<p>我们可以通过自定义错误页面&nbsp;<code>404.html</code>&nbsp;来处理 404 错误。</p>
<p>beego 更加人性化的还有一个设计就是支持用户自定义字符串错误类型处理函数，例如下面的代码，用户注册了一个数据库出错的处理页面：</p>
<pre class="language-go"><code>func dbError(rw http.ResponseWriter, r *http.Request){
    t,_:= template.New("dberror.html").ParseFiles(web.BConfig.WebConfig.ViewsPath+"/dberror.html")
    data :=make(map[string]interface{})
    data["content"] = "database is now down"
    t.Execute(rw, data)
}

func main() {
    web.ErrorHandler("dbError",dbError)
    web.Router("/", &amp;controllers.MainController{})
    web.Run()
}</code></pre>
<p>&nbsp;</p>
<p>一旦在入口注册该错误处理代码，那么你可以在任何你的逻辑中遇到数据库错误调用&nbsp;<code>this.Abort("dbError")</code>&nbsp;来进行异常页面处理。</p>
<p>&nbsp;</p>
<h2>2.1 Controller定义Error</h2>
<p>从 1.4.3 版本开始，支持 Controller 方式定义 Error 错误处理函数，这样就可以充分利用系统自带的模板处理，以及 context 等方法。</p>
<pre class="language-go"><code>type ErrorController struct {
    web.Controller
}

func (c *ErrorController) Error404() {
    c.Data["content"] = "page not found"
    c.TplName = "404.tpl"
}

func (c *ErrorController) Error501() {
    c.Data["content"] = "server error"
    c.TplName = "501.tpl"
}


func (c *ErrorController) ErrorDb() {
    c.Data["content"] = "database is now down"
    c.TplName = "dberror.tpl"
}</code></pre>
<p>&nbsp;</p>
<p>通过上面的例子我们可以看到，所有的函数都是有一定规律的，都是&nbsp;<code>Error</code>&nbsp;开头，后面的名字就是我们调用&nbsp;<code>Abort</code>&nbsp;的名字，例如&nbsp;<code>Error404</code>&nbsp;函数其实调用对应的就是&nbsp;<code>Abort("404")</code></p>
<p>我们就只要在&nbsp;<code>web.Run</code>&nbsp;之前采用&nbsp;<code>web.ErrorController</code>&nbsp;注册这个错误处理函数就可以了</p>
<pre class="language-go"><code>func main() {
    web.ErrorController(&amp;controllers.ErrorController{})
    web.Run()
}</code></pre>
<p>&nbsp;</p>