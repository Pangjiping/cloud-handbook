# **golang实现一个gRPC拦截器**

## **1. 什么是gRPC拦截器**

我们以etcd一个写请求的流程来看gRPC拦截器做了什么工作

当etcd处理一个写请求，比如 put hello world 时，首先etcd client会使用负载均衡算法选择一个etcd节点，发起gRPC调用；

然后etcd节点收到请求后经过gRPC拦截器、Quota模块后，进入KVServer模块...

拦截器，通俗一点理解就是在执行一段代码之前，先去执行另外一段代码。

拦截器就可以理解为gRPC生态中的中间件（是不是和web中间件非常类似），拦截器一般在做统一接口的认证工作

假设有一个方法`handler(ctx context.Context)`，我想要给这个方法赋予一个能力：允许在这个方法之前打印一行日志

<br>

## **2. gRPC拦截器分析**

以下使用golang来分析一个简单的拦截器逻辑

<br>

### **2.1 定义结构**

我们定义一个结构`interceptor`，这个结构包含两个参数，一个上下文信息`context`和处理器`handler`函数

```golang
type handler func(ctx context.Context)
type interceptor func(ctx context.Context, h handler)
```

<br>

### **2.2 申明赋值**

接下来，为了实现我们的目标，对每个`handler` 的每个操作，我们都需要经过拦截器，于是我们声明两个`interceptor`和`handler`的变量并赋值

```golang
var h = func(ctx context.Context) {
	fmt.Println("some logic ...")
}
var interceptor1 = func(ctx context.Context, h handler) {
	fmt.Println("intercept!")
	h(ctx)
}
```

<br>

### **2.3 编写执行函数**

我们执行一下函数，测试效果

```golang
func main() {
	var ctx context.Context
	var ceps []interceptor
    
	var h = func(ctx context.Context) {
		fmt.Println("some logic ...")
	}
	var interceptor1 = func(ctx context.Context, h handler) {
		fmt.Println("intercept!")
		h(ctx)
	}
 
	ceps = append(ceps, interceptor1)
	for _, cep := range ceps {
		cep(ctx, h)
	}
}
```

输出结果为：

```bash
$ go run main.go
 
intercept!
some logic ...
```

看起来我们的拦截器已经生效了，我们在`ceps`数组中再增加一个拦截器，看看会发生什么

```golang
var interceptor2 = func(ctx context.Context, h handler) {
	fmt.Println("intercept_2!")
	h(ctx)
}
ceps = append(ceps, interceptor2)
```

输出结果为：

```bash
$ go run main.go
 
intercept_1!
some logic ...
intercept_2!
some logic ...
```

可以看到，输出结果明显是不符合逻辑的

我们认为的拦截器是什么？不管我们中间经过了多少个拦截器的处理，都要保证`handler`函数只执行一次，也就是我们的业务逻辑只能执行一次

<br>

### **2.4 gRPC-go**

在gRPC-go的源码里有一个函数`chainUnaryClientInterceptors(cc)`，看函数名字也能猜出来是做什么

这个函数就是把所有的拦截器串联成了一个拦截器，这样保证了请求会经过所有拦截器，而最终`handler`函数只会被最后执行一次

那么将所有拦截器串联是如何做到的呢？

来看看这个函数的实现：

```golang
// chainUnaryClientInterceptors chains all unary client interceptors into one.
func chainUnaryClientInterceptors(cc *ClientConn) {
	interceptors := cc.dopts.chainUnaryInts
 
	// Prepend dopts.unaryInt to the chaining interceptors if it exists,
	// since unaryInt will be executed before any other chained interceptors.
	if cc.dopts.unaryInt != nil {
		interceptors = append([]UnaryClientInterceptor{cc.dopts.unaryInt}, interceptors...)
	}
	var chaindInt UnaryClientInterceptor
	if len(interceptors) == 0 {
		chaindInt = nil
	} else if len(interceptors) == 1 {
		chaindInt = interceptors[0]
	} else {
		chaindInt = func(ctx context.Context, method string, req, reply interface{},
			cc *ClientConn, invoker UnaryInvoker, opts ...CallOption) error {
			return interceptors[0](ctx, method, req, reply, cc, getChainUnaryInvoker(interceptors, 0, invoker), opts...)
		}
	}
 
	cc.dopts.unaryInt = chaindInt
}
```

重点在第二个if-else判断上，我们可以看到当拦截器数目超过一个时，会调用`getChainUnaryInvoker()`这个函数，再继续看看这个函数是如何把拦截器串联起来的

```golang
// getChainUnaryInvoker recursively generate the chained unary invoker.
func getChainUnaryInvoker(interceptors []UnaryClientInterceptor, curr int, finalInvoker UnaryInvoker) UnaryInvoker {
	if curr == len(interceptors)-1 {
		return finalInvoker
	}
 
	return func(ctx context.Context, method string, req, reply interface{}, cc *ClientConn, opts ...CallOption) error {
		return interceptors[curr+1](ctx, method, req, reply, cc, getChainUnaryInvoker(interceptors, curr+1, finalInvoker), opts...)
	}
}
```

可以看到`getChainUnaryInvoker()`其实就是一个递归函数，它返回了一个`UnaryInvoker`，其也是一个函数

```golang
type UnaryInvoker func(ctx context.Context, method string, req, reply interface{}, cc *ClientConn, opts ...CallOption) error
```

实际上这个`UnaryInvoker`函数实例化时会调用第`curr+1`个`interceptor`，也就会最终返回一个链式结构：

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220513172447725-1968917649.png)

最终将这个`finalInvoker`赋值给了`cc.dopts.unaryInt`，但注意到此时并没有调用拦截器，那么什么时候开始调用的呢？

chained拦截器在下面这个`Invoke()`函数中实现了真正的拦截器逻辑

```golang
err := c.cc.Invoke(ctx, "/helloworld.Greeter/SayHello", in, out, opts...)
```

```golang
func (cc *ClientConn) Invoke(ctx context.Context, method string, args, reply interface{}, opts ...CallOption) error {
	opts = combine(cc.dopts.callOptions, opts)
	if cc.dopts.unaryInt != nil {
		return cc.dopts.unaryInt(ctx, method, args, reply, cc, invoke, opts...)
	}
	return invoke(ctx, method, args, reply, cc, opts...)
}
```

还记得`cc.dopts.unaryInt`是什么吗？它就是我们最终生成的串联拦截器结构，从这个入口进行调用拦截器，最终就会调用所有的拦截器，而最后再执行`invoke()`这个核心业务逻辑

<br>

## **3. 实现一个拦截器**

<br>

### **3.1 重新定义数据结构**

我们之前的问题是，如何保证`handler`只执行一遍？

这里我们将原来的`handler`进行拆解，成为`invoker`，然后重新定义一个`handler`，用于在`invoker`之前处理一些逻辑

```golang
type invoker func(ctx context.Context, interceptors []interceptor, h handler) error
type handler func(ctx context.Context)
type interceptor func(ctx context.Context, h handler, ivk invoker) error
```

<br>

### **3.2 串联所有拦截器**

接下来我们实现一个把所有拦截器串联起来的方法

```golang
func getInvoker(ctx context.Context, interceptors []interceptor, curr int, ivk invoker) invoker {
	if curr == len(interceptors)-1 {
		return ivk
	}
	return func(ctx context.Context, interceptors []interceptor, h handler) error {
		return interceptors[curr+1](ctx, h, getInvoker(ctx, interceptors, curr+1, ivk))
	}
}
```

<br>

### **3.3 返回第一个interceptor作为入口**

```golang
func getChainInterceptor(ctx context.Context, interceptors []interceptor, ivk invoker) interceptor {
	if len(interceptors) == 0 {
		return nil
	} else if len(interceptors) == 1 {
		return interceptors[0]
	} else {
		return func(ctx context.Context, h handler, ivk invoker) error {
			return interceptors[0](ctx, h, getInvoker(ctx, interceptors, 0, ivk))
		}
	}
}
```

<br>

### **3.4 测试**

我们还是定义两个拦截器，看看是否将会串联执行

```golang
func main() {
	var ctx context.Context
	var ceps []interceptor
	var h = func(ctx context.Context) {
		fmt.Println("some logic before ...")
	}
 
	var interceptor1 = func(ctx context.Context, h handler, ivk invoker) error {
		h(ctx)
		return ivk(ctx, ceps, h)
	}
	var interceptor2 = func(ctx context.Context, h handler, ivk invoker) error {
		h(ctx)
		return ivk(ctx, ceps, h)
	}
	ceps = append(ceps, interceptor1, interceptor2)
 
	var ivk = func(ctx context.Context, interceptors []interceptor, h handler) error {
		fmt.Println("invoker start")
		return nil
	}
 
	cep := getChainInterceptor(ctx, ceps, ivk)
	cep(ctx, h, ivk)
}
```

输出结果为：

```bash
$ go run main.go
 
some logic before ...
some logic before ...
invoker start
```

我们可以看到在调用真正的业务逻辑函数`invoker()`之前，调用了两个拦截器，而业务逻辑只被执行了一次，这就实现了一个简单的拦截器

<br>

## **Reference**
* https://zhuanlan.zhihu.com/p/80023990
* https://zhuanlan.zhihu.com/p/376438559
* https://blog.csdn.net/Gassuih/article/details/116146535