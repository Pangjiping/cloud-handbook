# **golang运行时库runtime.Caller()方法**

## **runtime.Caller()方法介绍**

`runtime.Caller()`函数的签名如下：

```golang
func Caller(skip int) (pc uintptr, file string, line int, ok bool)
```

可以看到有一个传入参数`skip`:

* `skip=0`：`Caller()`会报告`Caller()`的调用者的信息
* `skip=1`：`Caller()`会报告`Caller()`的调用者的调用者的信息
* `skip=2`：...

有四个返回值：
* `pc`：调用栈标识符
* `file`：带路径的完整文件名
* `line`：该调用在文件中的行号
* `ok`：是否可以获得信息

`runtime.Caller()`返回值中第一个返回值是一个调用栈标识，通过它我们能拿到调用栈的函数信息`*runtime.Func`，再进一步获取到调用者的函数名字，这里面会用到的函数和方法如下：

```golang
func FuncForPC(pc uintptr) *Func
func (*Func) Name()
```

`runtime.FuncForPC()`函数返回一个表示调用栈标识符`pc`对应的调用栈的`*Func`

如果该调用栈标识符没有对应的调用栈，函数会返回`nil`

`Name()`方法返回该调用栈所调用的函数的名字，上面说了`runtime.FuncForPC()`有可能会返回`nil`，不过`Name()`方法在实现的时候做了这种情况的判断，避免出现panic：

```golang
func (f *Func) Name() string {
    if f == nil {
        return ""
    }
    fn := f.raw()
    if fn.isInlined() { // inlined version
        fi := (*funcinl)(unsafe.Pointer(fn))
        return fi.name
    }
    return funcname(f.funcInfo())
}
```

<br>

## **2. runtime.Caller()构建日志信息**

下面使用一个例子来获取调用者的信息：

```golang
func getCallerInfo(skip int) (info string) {
	pc, file, lineNo, ok := runtime.Caller(skip)
	if !ok {
		info = "runtime.Caller() failed"
	}
 
	funcName := runtime.FuncForPC(pc).Name()
	fileName := path.Base(file) // Base函数返回路径的最后一个元素
	return fmt.Sprintf("FuncName:%s, file:%s, line:%d", funcName, fileName, lineNo)
}
 
func main() {
	// 打印getCallerInfo函数自身的信息
	fmt.Println(getCallerInfo(0))
 
	// 打印getCallerInfo函数的调用者的信息
	fmt.Println(getCallerInfo(1))
}
```

函数执行结果为：

```bash
$ go run main.go
FuncName:main.getCallerInfo, file:main.go, line:10
FuncName:main.main, file:main.go, line:25
```

<br>