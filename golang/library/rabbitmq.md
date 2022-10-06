# **golang-rabbitmq客户端**

<br>

## **1. RabbitMQ介绍**

RabbitMQ是采用Erlang编程语言实现的高级消息队列协议AMQP（Advanced Message Queuing Protocol）的开源消息队列中间件

消息队列中间件的作用：
* 应用解耦
* 流量削峰
* 异步处理
* 缓存存储
* 消息通信
* 提高系统扩展性

<br>

### **1.1 RabbitMQ特点**

* 可靠性：通过持久化和传输确认等来确保消息传递的可靠性
* 扩展性：多个RabbitMQ节点可以组成集群
* 高可用：队列可以在RabbitMQ集群中设置镜像，如此一来即使部分节点挂掉，队列仍然可以使用
* 多种协议支持：原生支持AMQP，也能支持STOMP、MQTT等协议
* 丰富的客户端：常用的编程语言都有客户端
* 管理界面：自带一个webUI界面
* 插件机制：RabbitMQ自己提供了多种插件，可以按需扩展Plugins

<br>

### **1.2 RabbitMQ基本概念**

总体上看RabbitMQ是一个生产者和消费者模型，用于实现消息的接收、存储、转发

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519134928323-1114831585.png)

**Producer(生产者)**：消息的生产方，投递方。

**Consumer(消费者)**：消息的消费者。

**RabbitMQ Broker(RabbitMQ代理)**：RabbitMQ服务节点。在单机环境中，就是代表RabbitMQ服务器。

**Queue(队列)**：在RabbitMQ中Queue是存储消息数据的唯一形式。

**Binding(绑定)**：在RabbitMQ中的Binding是Exchange将message路由给Queue所需遵循的规则。如果要指定“交换机E将消息路由给队列Q”，那么Q就需要与E进行绑定。绑定操作需要定义一个可选的路由键（routing key）属性给某些类型的交换机。路由键的意义在于从发送给交换机的众多消息中选择出某些消息，将其路由给绑定的队列。

**RoutingKey(路由键)**：消息投递给交换机，通常会指定一个RoutingKey，通过这个路由键来明确消息的路由规则。RoutingKey 通常是生产者和消费者有协商一致的key策略，消费者就可以合法从生产者手中获取数据。这个RoutingKey主要当Exchange交换机模式为设定为direct和topic模式的时候使用，fanout模式不使用RoutingKey。

**Exchange(交换机)**：生产者将消息发送给交换机，再由交换机将消息路由到对应的队列中。交换机有四种类型：fanout、direct、topic、headers

<br>

### **1.3 Exchange**

交换机有四种类型：fanout、direct、topic、headers

<br>

#### **1.3.1 fanout**

可以把fanout理解为扇形交换机

其将发送带该类型交换机的消息路由到所有与该交换机绑定的队列中，如同一个扇形一样扩散给各个队列

fanout类型的交换机会忽略RoutingKey的存在，将消息直接广播到绑定的所有队列中

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519140149245-1615175719.png)

<br>

#### **1.3.2 direct**

可以把direct理解为直连交换机

其根据消息携带的RoutingKey将消息投递到相应的队列中

direct类型的交换机(exchange)是RabbitMQ Broker的默认类型，它有一个特别的属性对一些简单的应用来说是非常有用的，在使用这个类型的Exchange时，可以不必指定routing key的名字，在此类型下创建的Queue有一个默认的routing key，这个routing key一般同Queue同名

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519140354786-1721934923.png)

<br>

#### **1.3.3 topic**

可以把topic理解为主题交换机

topic交换机在RoutingKey和BindKey匹配规则上更加灵活，同样是将消息路由到RoutingKey和BindKey相匹配的队列中，但是匹配规则有如下特点：
* RoutingKey是一个使用.分割的字符串，例如：`go.log.info`、`java.log.error`
* BindKey也是一个使用.分割的字符串，但是在BindKey中可以使用两种特殊字符`*`和`#`用于匹配一个单词，#用于匹配多规格单词（零个或多个单词）
RoutingKey和BindKey是一种“模糊匹配”，那么一个消息可能会被发送到一个或者多个队列中

无法匹配的消息将会被丢弃或者返回给生产者

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519141439958-2095573614.png)

<br>

#### **1.3.4 headers**

可以把headers理解为头交换机

headers类型的交换机使用的不是很多

关于headers exchange比较容易理解的解释是：

有时消息的路由操作会涉及到多个属性，此时使用消息头就比用路由键更容易表达，头交换机（headers exchange）就是为此而生的。头交换机使用多个消息属性来代替路由键建立路由规则。通过判断消息头的值能否与指定的绑定相匹配来确立路由规则。
 
我们可以绑定一个队列到头交换机上，并给他们之间的绑定使用多个用于匹配的头（header）。这个案例中，消息代理得从应用开发者那儿取到更多一段信息，换句话说，它需要考虑某条消息（message）是需要部分匹配还是全部匹配。上边说的“更多一段消息”就是"x-match"参数。当"x-match"设置为“any”时，消息头的任意一个值被匹配就可以满足条件，而当"x-match"设置为“all”的时候，就需要消息头的所有值都匹配成功。
 
头交换机可以视为直连交换机的另一种表现形式。头交换机能够像直连交换机一样工作，不同之处在于头交换机的路由规则是建立在头属性值之上，而不是路由键。路由键必须是一个字符串，而头属性值则没有这个约束，它们甚至可以是整数或者哈希值（字典）等。

<br>

### **1.4 RabbitMQ工作流程**

**消息生产流程**
* 消息生产者与RabbitMQ Broker建立一个连接，建立连接之后开启一个信道channel
* 声明一个交换机，并设置与其相关的属性（交换机类型、持久化等）
* 声明一个队列，并设置其相关属性（排他性、持久化、自动删除等）
* 通过路由键将交换机和队列绑定
* 消息生产者发送消息给RabbitMQ Broker，消息中包含了路由键、交换机等信息，交换机根据接收的路由键查找匹配的队列
* 查找匹配成功，将消息存储到队列中
* 查找匹配失败，根据生产者配置的属性选择丢弃或者退回给生产者
* 关闭信道channel，关闭连接

**消息消费流程**
* 消费者与RabbitMQ Broker建立连接，连接建立之后开启一个channel
* 消费者向RabbitMQ Broker请求消费者相应队列中的消息
* 等待RabbitMQ Broker回应并投递相应队列中的消息，消费者接收消息
* 消费者确认接收消息（ACK），RabbitMQ Broker删除已经确认的消息
* 关闭信道channel，关闭连接

<br>

## **2. RabbitMQ安装**

个人学习推荐使用docker安装

直接安装management版本即可，搜索镜像

```bash
$ docker search rabbitmq:management
```

拉取镜像

```bash
$ docker pull rabbitmq:management
management: Pulling from library/rabbitmq
7b1a6ab2e44d: Pull complete 
37f453d83d8f: Pull complete 
e64e769bc4fd: Pull complete 
c288a913222f: Pull complete 
12addf9c8bf9: Pull complete 
eaeb088e057d: Pull complete 
b63d48599313: Pull complete 
05c99d3d2a57: Pull complete 
43665bfbc3f9: Pull complete 
f14c7d7911b1: Pull complete 
Digest: sha256:4c4b66ad5ec40b2c27943b9804d307bf31c17c8537cd0cd107236200a9cd2814
Status: Downloaded newer image for rabbitmq:management
docker.io/library/rabbitmq:management
```

启动RabbitMQ容器

```bash
$ docker run -d -p 15672:15672 -p 5672:5672 -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=admin --name rabbitmq --hostname=rabbitmqhostone rabbitmq:management
```

参数含义如下：
* -d 后台运行
* -p 端口映射
* -name 指定容器名称
* RABBITMQ_DEFAULT_USER指定用户账号，不指定默认为guest
* RABBITMQ_DEFAULT_PASS指定用户密码，不指定默认为guest

访问`http://ip:15672`是RabbitMQ的webUI界面，默认用户名密码为guest/guest

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519144652014-1548048433.png)

<br>

## **3. go-rabbitmq**

推荐依赖包：github.com/streadway/amqp

demo的目录结构如下：

```bash
$ tree
.
├── consumer
│   └── consumer.go
├── go.mod
├── go.sum
├── lib
│   ├── common-func.go
│   └── error.go
├── producer
│   └── producer.go
├── task
│   └── task.go
└── worker
    └── worker.go
```

<br>

### **3.1 客户端连接**

```golang
// RabbitMQConn 获取rabbitMQ Broker连接
func RabbitMQConn() (conn *amqp.Connection, err error) {
	var (
		user string = "admin"
		pwd  string = "admin"
		host string = "xx.xx.xx.xx"
		port string = "5672"
	)
 
	url := "amqp://" + user + ":" + pwd + "@" + host + ":" + port + "/"
 
	// 新建连接
	conn, err = amqp.Dial(url)
	return
}
```

<br>

### **3.2 基础队列使用**

简单队列模式是RabbitMQ的常规用法，简单理解就是消息生产者发送消息给一个队列，然后消息的消费者从队列中读取消息

当多个消费者订阅同一个队列的时候，队列中的消息是平均分摊给多个消费者处理

首先定义一个消息的生产者producer：

```golang
type simpleDemo struct {
	Name string `json:"name"`
	Addr string `json:"addr"`
}
 
func main() {
	// 连接rabbitMQ服务器
	conn, err := lib.RabbitMQConn()
	lib.ErrorHandle(err, lib.ErrConnectRabbit)
	defer conn.Close()
 
	// 新建一个channel
	ch, err := conn.Channel()
	lib.ErrorHandle(err, lib.ErrOpenChannel)
	defer ch.Close()
 
	// 声明或者创建一个队列来保存消息
	q, err := ch.QueueDeclare(
		"simple:queue", // name
		false,          // durable
		false,          // delete when unused
		false,          // exclusive
		false,          // no-wait
		nil,            // argument
	)
	lib.ErrorHandle(err, lib.ErrDeclareQueue)
	data := simpleDemo{
		Name: "Tom",
		Addr: "Shanghai",
	}
	dataBytes, err := json.Marshal(data)
	lib.ErrorHandle(err, lib.ErrMarshalJSON)
 
	err = ch.Publish(
		"",     // exchange
		q.Name, // routing key
		false,  // mandatory
		false,  // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        dataBytes,
		},
	)
	lib.ErrorHandle(err, lib.ErrPublishMsg)
	log.Printf(" [x] Sent %s", dataBytes)
}
```

定义消息消费者consumer：

```golang
func main() {
	conn, err := lib.RabbitMQConn()
	lib.ErrorHandle(err, lib.ErrConnectRabbit)
	defer conn.Close()
 
	ch, err := conn.Channel()
	lib.ErrorHandle(err, lib.ErrOpenChannel)
	defer ch.Close()
 
	q, err := ch.QueueDeclare(
		"simple:queue", // name
		false,          // durable
		false,          // delete when unused
		false,          // exclusive
		false,          // no-wait
		nil,            // args
	)
	lib.ErrorHandle(err, lib.ErrDeclareQueue)
	// 定义一个消费者
	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		true,   // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	lib.ErrorHandle(err, lib.ErrRegisterConsumer)
 
	go func() {
		for d := range msgs {
			log.Printf("Received a message: %s", d.Body)
		}
	}()
 
	log.Printf("[*] Waiting for messages. To exit press CTRL+C")
	select {}
}
```

我们开启一个生产者和一个消费者，运行结果为：

```bash
$ go run producer.go
2022/05/19 16:06:25  [x] Sent {"name":"Tom","addr":"Shanghai"}

$ go run consumer.go
2022/05/19 16:06:33 [*] Waiting for messages. To exit press CTRL+C
2022/05/19 16:06:33 Received a message: {"name":"Tom","addr":"Shanghai"}
```

<br>

### **3.3 工作队列**

工作队列也被称为任务队列

任务队列是为了避免等待执行一些耗时的任务，而是将需要执行的任务封装为消息发送给工作队列，后台运行的工作进程将任务消息取出来并执行相关任务

多个后台工作进程同时进行，他们之间共享任务（抢占）

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519161257408-1069657068.png)

定义一个任务生产者，用于生产任务消息

```golang
func bodyFrom(args []string) string {
	var s string
	if (len(args) < 2) || os.Args[1] == "" {
		s = "no task"
	} else {
		s = strings.Join(args[1:], " ")
	}
	return s
}
 
func main() {
	conn, err := lib.RabbitMQConn()
	lib.ErrorHandle(err, lib.ErrConnectRabbit)
	defer conn.Close()
 
	ch, err := conn.Channel()
	lib.ErrorHandle(err, lib.ErrOpenChannel)
	defer ch.Close()
 
	q, err := ch.QueueDeclare(
		"task:queue", // name
		false,        // durable
		false,        // delete when unused
		false,        // exclusive
		false,        // no-wait
		nil,          // args
	)
	lib.ErrorHandle(err, lib.ErrDeclareQueue)
 
	body := bodyFrom(os.Args)
	err = ch.Publish(
		"",
		q.Name,
		false,
		false,
		amqp.Publishing{
			ContentType:  "text/plain",
			DeliveryMode: amqp.Persistent,
			Body:         []byte(body),
		},
	)
	lib.ErrorHandle(err, lib.ErrPublishMsg)
	log.Printf("sent %s", body)
}
```

定义worker：

```golang
func main() {
	conn, err := lib.RabbitMQConn()
	lib.ErrorHandle(err, lib.ErrConnectRabbit)
	defer conn.Close()
 
	ch, err := conn.Channel()
	lib.ErrorHandle(err, lib.ErrOpenChannel)
	defer ch.Close()
 
	q, err := ch.QueueDeclare(
		"task:queue",
		false,
		false,
		false,
		false,
		nil)
	lib.ErrorHandle(err, lib.ErrDeclareQueue)
 
	// 将预取计数器设置为1
	// 在并行处理中将消息分配给不同的工作进程
	err = ch.Qos(
		1,     // prefetch count
		0,     // prefetch size
		false, // global
	)
	lib.ErrorHandle(err, lib.ErrSetQoS)
 
	msgs, err := ch.Consume(
		q.Name,
		"",
		false,
		false,
		false,
		false,
		nil,
	)
	lib.ErrorHandle(err, lib.ErrRegisterConsumer)
 
	forever := make(chan bool)
	go func() {
		for d := range msgs {
			log.Printf("Received a message: %s", d.Body)
			log.Printf("Done")
			d.Ack(false)
		}
	}()
 
	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}
```

我们开启两个worker，运行结果为：

```bash
$ go run task.go hello world
2022/05/19 16:03:31 sent hello world
$ go run task.go hello golang
2022/05/19 16:03:53 sent hello golang
$ go run task.go hello rabbitmq
2022/05/19 16:03:59 sent hello rabbitmq
```

```bash
$ go run worker.go
2022/05/19 16:03:44  [*] Waiting for messages. To exit press CTRL+C
2022/05/19 16:03:44 Received a message: hello world
2022/05/19 16:03:44 Done
2022/05/19 16:03:53 Received a message: hello golang
2022/05/19 16:03:53 Done
```

```bash
$ go run worker.go
2022/05/19 16:03:47  [*] Waiting for messages. To exit press CTRL+C
2022/05/19 16:03:59 Received a message: hello rabbitmq
2022/05/19 16:03:59 Done
```

同时可以查看一下RabbitMQ的webUI，看看我们的工作队列情况

![img](https://img2022.cnblogs.com/blog/2794988/202205/2794988-20220519160912586-430805854.png)

<br>

## **Reference**
* https://developer.aliyun.com/article/769883
* https://blog.csdn.net/qq_42402854/article/details/124820511
* https://www.jianshu.com/p/179467f5cc85
* https://www.rabbitmq.com