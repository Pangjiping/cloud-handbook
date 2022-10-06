<h2>1. 自定义response</h2>
<p>对于具体的项目而言，我们需要基于JSON()自定义一个方便好用的response</p>
<p>比如下面这种形式：</p>
<pre class="language-go"><code>type Response struct {
	StatusCode int         `json:"status_code" ` // 业务状态码
	Message    string      `json:"message" `     // 提示信息
	Data       interface{} `json:"data" `        // 任何数据
	Meta       Meta        `json:"meta" `        // 源数据，存储比如请求ID、分页信息等
	Errors     []ErrorItem `json:"errors" `      // 错误提示，比如xx字段不能为空等
}

type Meta struct {
	RequestID string `json:"request_id" `
	Page      int    `json:"page" `
}

type ErrorItem struct {
	Key   string `json:"key" `
	Value string `json:"value" `
}

func NewResponse() *Response {
	return &amp;Response{
		StatusCode: 200,
		Message:    "success",
		Data:       nil,
		Meta: Meta{
			RequestID: "1234", // 可以是uuid
			Page:      1,
		},
		Errors: []ErrorItem{},
	}
}</code></pre>
<p>　　</p>
<p>同时我们封装gin.Context来做一些便捷的返回response的操作</p>
<pre class="language-go"><code>// Wrapper 封装了gin.Context
type Wrapper  struct {
    ctx *gin.Context
}

func WrapContext(ctx *gin.Context) *Wrapper {
    return &amp;Wrapper{ctx: ctx}
}

// Success 输出成功信息
func (wrapper *Wrapper) Success(data  interface {}) {
    resp := NewResponse()
    resp.Data = data
    wrapper.ctx.JSON(http.StatusOK, resp)
}

// Error 输出错误信息
func (wrapper *Wrapper) Error(statusCode int, errMessage string) {
    resp := NewResponse()
    resp.StatusCode = statusCode
    resp.Message = errMessage
    wrapper.ctx.JSON(statusCode, resp)
}</code></pre>
<p>&nbsp;</p>
<p>现在就可以使用封装gin.Context的自定义结构体Wrapper来做响应的返回了：</p>
<pre class="language-go"><code>func main() {
    router := gin.Default()
    router.GET( "/" ,  func (ctx *gin.Context) {
        WrapContext(ctx).Success( "hello world" )
    })
    router.Run()
}</code></pre>
<p>　　</p>
<h2>2. 日志中间件</h2>
<p>我们有时候需要一些日志来判断做一些错误处理，虽然gin已经默认使用了一个很不错的中间件，但可能我们需要的信息并不在其中</p>
<p>下面我们自定义一个日志中间件，首先应该明确我们在日志中应该记录什么？</p>
<p>一般的日志中间件就会记录这些信息：请求头、响应体、响应时间、请求方法、请求IP等</p>
<p>&nbsp;</p>
<p>首先实现一个方法来请求体：</p>
<pre class="language-go"><code>func getRequestBody(ctx *gin.Context)  interface {} {
    switch ctx.Request.Method {
    case http.MethodGet:
        return ctx.Request.URL.Query()
    case http.MethodPost:
        fallthrough
    case http.MethodPut:
        fallthrough
    case http.MethodPatch:
        var bodyBytes []byte
        bodyBytes, err := ioutil.ReadAll(ctx.Request.Body)
        if err != nil {
            return nil
        }
        ctx.Request.Body = ioutil.NopCloser(bytes.NewBuffer(bodyBytes))
        return string(bodyBytes)
    }
    return nil
}</code></pre>
<p>　　</p>
<p>我们需要定义一个结构体和方法</p>
<pre class="language-go"><code>// bodyLogWriter 定义一个存储响应内容的结构体
type bodyLogWriter  struct {
    gin.ResponseWriter
    body *bytes.Buffer
}

// Write 读取响应数据
func (w bodyLogWriter) Write(b []byte) (int, error) {
    w.body.Write(b)
    return w.ResponseWriter.Write(b)
}</code></pre>
<p>&nbsp;</p>
<p>在bodyLogWriter结构体中封装了gin的responseWriter，然后在重写的Write方法中，首先向bytes.Buffer中写数据，然后响应</p>
<p>这保证了我们可以正确的获取到响应内容</p>
<p>最后就是中间件的实现，其中最重要的一点就是用我们自定义的bodyLogWriter来代替ctx.Writer，保证响应会保留一份在bytes.Buffer中</p>
<pre class="language-go"><code>// RequestLog gin请求日志中间件
func RequestLog(ctx *gin.Context) {
	t := time.Now()

	// 初始化bodyLogWriter
	blw := &amp;bodyLogWriter{
		body:           bytes.NewBufferString(""),
		ResponseWriter: ctx.Writer,
	}
	ctx.Writer = blw

	// 获取请求信息
	requestBody := getRequestBody(ctx)

	ctx.Next()

	// 记录响应信息
	// 请求时间
	costTime := time.Since(t)

	// 响应内容
	responseBody := blw.body.String()

	// 日志格式
	logContext := make(map[string]interface{})
	logContext["request_uri"] = ctx.Request.RequestURI
	logContext["request_method"] = ctx.Request.Method
	logContext["refer_service_name"] = ctx.Request.Referer()
	logContext["refer_request_host"] = ctx.ClientIP()
	logContext["request_body"] = requestBody
	logContext["request_time"] = t.String()
	logContext["response_body"] = responseBody
	logContext["time_used"] = fmt.Sprintf("%v", costTime)
	logContext["header"] = ctx.Request.Header
	log.Println(logContext)
}</code></pre>
<p>当然最后日志在控制台打印了，如果有持久化的需求可以异步持久化到本地或者远程的数据库</p>
<p>&nbsp;</p>
<h2>3. 跨域中间件</h2>
<pre class="language-go"><code>func CORSMiddleWare(ctx *gin.Context) {
	method := ctx.Request.Method

	// set response header
	ctx.Header( "Access-Control-Allow-Origin" , ctx.Request.Header.Get( "Origin" ))
	ctx.Header( "Access-Control-Allow-Credentials" ,  "true" )
	ctx.Header( "Access-Control-Allow-Headers" ,
		"Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With" )
	ctx.Header( "Access-Control-Allow-Methods" ,  "GET,POST,PUT,PATCH,DELETE,OPTIONS" )

	// 默认过滤options和head这两个请求，使用204返回
	if method == http.MethodOptions || method == http.MethodHead {
		ctx.AbortWithStatus(http.StatusNoContent)
		return
	}

	ctx.Next()
}</code></pre>
<p>　　</p>
<p>&nbsp;</p>