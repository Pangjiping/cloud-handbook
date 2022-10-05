# **构造一个logger**

一个实用的logger需要提供以下这些功能：

* 支持把日志写入多个输出流中，比如可以选择性的让测试、开发环境同时向控制台和日志文件输出日志，生产环境只输出到日志文件中
* 支持多级别的日志等级，常见的有：TRACE、DEBUG、INFO、WARN、ERROR、PANIC等
* 支持结构化输出，结构化输出常用的就是JSON格式，这样可以让统一日志平台通过logstash之类的组件把日志聚合到日志平台上
* 需要支持日志切割log rotation
* 在log entry中除了主动记录的信息外，还要包括如打印日志的函数、所在的文件、行号、记录时间等

<br>

## **1. Log日志库**

使用log记录日志，默认会输出到控制台，比如下面这个例子：

```golang
func main() {
	simpleHTTPGet("www.baidu.com")
	simpleHTTPGet("https://www.baidu.com")
}
 
func simpleHTTPGet(url string) {
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Error fetching url %s: %s", url, err.Error())
	} else {
		log.Printf("Status Code for %s: %s", url, resp.Status)
		resp.Body.Close()
	}
	return
}
```

输出信息如下：

```golang
2022/05/31 10:40:45 Error fetching url www.baidu.com: Get "www.baidu.com": unsupported protocol scheme ""
2022/05/31 10:40:45 Status Code for https://www.baidu.com: 200 OK
```

go原生的logger也支持把日志输出到指定的文件中，通过`log.SetOutput`可以把任何`io.Writer`的实现设置成日志的输出。我们把日志输出到一个指定文件：

```golang
func main() {
	setupLogger()
	simpleHTTPGet("www.baidu.com")
	simpleHTTPGet("https://www.baidu.com")
}
 
func setupLogger() {
	logFileLocation, _ := os.OpenFile("/tmp/test.log", os.O_CREATE|os.O_APPEND|os.O_RDWR, 0644)
	log.SetOutput(logFileLocation)
}
```

原生logger用法非常简单，对于一些简单的开发调试来讲基本是适用的，但是用在项目中存在着以下不足：

* 仅限基本的日志级别，只有一个`Print`选项
* 对于错误日志，有`Fatal`和`Panic`，不支持`Error`
* 无结构化能力，只是简单的文本输出
* 没有日志切割能力

<br>

## **2. Zap日志库**

zap是Uber开源的日志库，具备高性能的特性

zap高性能的一大原因是，不用反射。日志里每个要写入的字段都要携带类型

```golang
logger.Info(
    "Success...",
    zap.String("statusCode", resp.Status),
    zap.String("url",url))
```

上面向日志里写入了一条记录，Message是"Success..."，另外写入了两个字符串键值对。

zap针对日志里要写入的字段，每个类型都有一个对应的方法将字段转成zap.Field类型，比如：

```golang
zap.Int('key', 123)
zap.Bool('key', true)
zap.Error('err', err)
zap.Any('arbitraryType', &User{})
```

<br>

### **2.1 zap的简单使用**

首先需要引入依赖

```bash
$ go get -u go.uber.org/zap
```

之后我们做一下简单的初始化工作就可以使用zap logger了，其实zap提供了三种初始化方法，我们就使用`zap.NewProduction()`即可

我们简单修改一下之前的代码，引入`zap.logger`：

```golang
var logger *zap.Logger
 
func main() {
	simpleHttpGet("www.baidu.com")
	simpleHttpGet("https://www.baidu.com")
}
 
func simpleHttpGet(url string) {
	resp, err := http.Get(url)
	if err != nil {
		logger.Error("Failed...", zap.String("Error", err.Error()))
	} else {
		logger.Info("Success...", zap.String("StatusCode", resp.Status), zap.String("Url", url))
		resp.Body.Close()
	}
}
 
func init() {
	logger, _ = zap.NewProduction()
}
```

运行程序，可以在控制台看到更加详细的输出，其中包括了go原生log不支持的一些信息，包括调用栈信息、时间戳、日志等级，json格式化输出

```json
{"level":"error","ts":1654150127.123799,"caller":"logger/main.go:27","msg":"Failed...","Error":"Get \"www.baidu.com\": unsupported protocol scheme \"\"","stacktrace":"main.simpleHttpGet\n\t/Users/pangjiping/gopath/src/blog/logger/main.go:27\nmain.main\n\t/Users/pangjiping/gopath/src/blog/logger/main.go:14\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:255"}
{"level":"info","ts":1654150127.293559,"caller":"logger/main.go:30","msg":"Success...","StatusCode":"200 OK","Url":"https://www.baidu.com"}
```

<br>

### **2.2 zap的定制化**

对zap做简单定制，让其将日志输出到指定文件，并且将时间戳转为日期的格式

修改`init()`函数完成`logger`的初始化工作即可

```golang
func init() {
	encoderConfig := zap.NewProductionEncoderConfig()
	// 设置日志记录中时间的格式
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	// 日志encoder还是json encoder，把日志行格式化程json格式的
	encoder := zapcore.NewJSONEncoder(encoderConfig)
 
	file, _ := os.OpenFile("./test.log", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	fileWriteSyncer := zapcore.AddSync(file)
 
	core := zapcore.NewTee(
		// 控制台输出
		zapcore.NewCore(encoder, zapcore.AddSync(os.Stdout), zapcore.DebugLevel),
		// 文件输出
		zapcore.NewCore(encoder, fileWriteSyncer, zapcore.DebugLevel),
	)
	logger = zap.New(core)
}
```

现在我们在控制台得到的输出日志为：

```json
{"level":"error","ts":"2022-06-02T14:23:19.639+0800","msg":"Failed...","Error":"Get \"www.baidu.com\": unsupported protocol scheme \"\""}
{"level":"info","ts":"2022-06-02T14:23:19.815+0800","msg":"Success...","StatusCode":"200 OK","Url":"https://www.baidu.com"}
```

<br>

### **2.3 日志切割**

zap本身不支持日志切割，可以借助另一个库lumberjack完成日志切割

```golang
func getFileLogWriter() (writeSyncer zapcore.WriteSyncer) {
	// 使用 lumberjack 实现 log rotate
	lumberJackLogger := &lumberjack.Logger{
		Filename:   "/tmp/test.log",
		MaxSize:    100, // 单个文件最大100M
		MaxBackups: 60,  // 多于 60 个日志文件后，清理较旧的日志
		MaxAge:     1,   // 一天一切割
		Compress:   false,
	}
 
	return zapcore.AddSync(lumberJackLogger)
}
```

<br>

### **2.4 封装**

```golang
package zlog
 
import (
	"os"
	"path"
	"runtime"
 
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)
 
var logger *zap.Logger
 
func init() {
	encoderConfig := zap.NewProductionEncoderConfig()
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	encoder := zapcore.NewJSONEncoder(encoderConfig)
 
	fileWriteSyncer := getFileLogWriter()
 
	core := zapcore.NewTee(
		zapcore.NewCore(encoder, zapcore.AddSync(os.Stdout), zap.DebugLevel),
		zapcore.NewCore(encoder, fileWriteSyncer, zapcore.DebugLevel),
	)
 
	logger = zap.New(core)
}
 
func getFileLogWriter() (writeSyncer zapcore.WriteSyncer) {
	lumberJackLogger := &lumberjack.Logger{
		Filename:   "./debug.log",
		MaxSize:    100,
		MaxBackups: 60,
		MaxAge:     1,
		Compress:   false,
	}
 
	return zapcore.AddSync(lumberJackLogger)
}
 
func Info(message string, fields ...zap.Field) {
	callerFields := getCallerInfoForLog()
	fields = append(fields, callerFields...)
	logger.Info(message, fields...)
}
 
func Debug(message string, fields ...zap.Field) {
	callerFields := getCallerInfoForLog()
	fields = append(fields, callerFields...)
	logger.Debug(message, fields...)
}
 
func Error(message string, fields ...zap.Field) {
	callerFields := getCallerInfoForLog()
	fields = append(fields, callerFields...)
	logger.Error(message, fields...)
}
 
func Warn(message string, fields ...zap.Field) {
	callerFields := getCallerInfoForLog()
	fields = append(fields, callerFields...)
	logger.Warn(message, fields...)
}
 
func getCallerInfoForLog() (callerFields []zap.Field) {
	pc, file, line, ok := runtime.Caller(2)
	if !ok {
		return
	}
 
	funcName := runtime.FuncForPC(pc).Name()
	funcName = path.Base(funcName) // 只保留函数名
 
	callerFields = append(callerFields, zap.String("func", funcName), zap.String("file", file), zap.Int("line", line))
	return
}
```

<br>