# **gRPC入门**

使用gRPC输出一个Hello World

<br>

## **四类服务方法**

gRPC支持四类服务方法，分别为

* 单项RPC
* 服务端流式RPC
* 客户端流式RPC
* 双向流式RPC

**单项RPC**

客户端发送一个请求给服务端，从服务端获取一个应答，就像一次普通的函数调用

```protobuf
rpc SayHello(HelloRequest) returns (HelloResponse){}
```

**服务端流式RPC**

客户端发送一个请求给服务端，可以获取一个数据流，用来读取一系列消息。客户端从反悔的数据流里一直读取直到没有更多消息为止

```protobuf
rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse){}
```

**客户端流式RPC**

客户端提供的一个数据流写入并发送一系列消息给服务端。一旦客户端完成消息写入，就等待服务端读取这些消息并返回应答

```protobuf
rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse){}
```

**双向流式RPC**

两边都可以分别通过一个读写数据流来发送一系列消息。这两个数据流操作是相互独立的，所以客户端和服务端能按照其希望的任意顺序读写，例如：服务端可以在写应答前等待所有的客户端消息，或者它可以先读一个消息再写一个消息，或者是读写相结合的其他方式。每个数据流里消息的顺序都会被保持。

```protobuf
rpc BidiHello(stream HelloRequest) returns (stream HelloResponse){}
```

<br>

## **gRPC实战**

安装protobuf编译器

```perl
pangjiping@pangjipingdeMacBook-Pro ~ % brew install protobuf

pangjiping@pangjipingdeMacBook-Pro ~ % protoc --version
libprotoc 3.21.9
```

**hello服务**

* 编写服务端`.proto`文件
* 编写服务端`.pb.go`文件并同步给客户端
* 编写服务端提供接口的代码
* 编写客户端调用接口的代码

**目录结构**

```perl
pangjiping@pangjipingdeMacBook-Pro hello % tree .
.
├── client
│   ├── main.go
│   └── proto
│       └── hello
│           └── hello.pb.go
├── go.mod
├── go.sum
└── server
    ├── controller
    │   └── hello_controller
    │       └── hello_server.go
    ├── main.go
    └── proto
        └── hello
            ├── hello.pb.go
            └── hello.proto
```

**server proto文件**

编写server proto文件如下:

```proto
syntax = "proto3"; // 指定proto版本

option go_package = "./;hello";

package hello; // 指定包名

// 定义Hello服务

service Hello {
  // 定义 SayHello 方法
  rpc SayHello(HelloRequest) returns (HelloResponse) {}

  // 定义 LotsOfReplies 方法
  rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse) {}
}

// HelloRequest请求结构
message HelloRequest {
  string name = 1;
}

// HelloResponse响应结构
message HelloResponse {
  string message = 1;
}
```

切换到对应目录下，生成`.pb.go`文件

```perl
pangjiping@pangjipingdeMacBook-Pro hello % protoc -I . --go_out=plugins=grpc:. ./hello.proto
```

同时将生成的`hello.pb.go`文件复制到客户端一份

编写服务端提供接口的代码

```golang
package hello_controller

import (
 "context"
 "fmt"
 "hello/server/proto/hello"
)

type HelloController struct {
}

func (h *HelloController) SayHello(ctx context.Context, in *hello.HelloRequest) (*hello.HelloResponse, error) {
 return &hello.HelloResponse{
  Message: fmt.Sprintf("%s", in.Name),
 }, nil
}

func (h *HelloController) LotsOfReplies(in *hello.HelloRequest, stream hello.Hello_LotsOfRepliesServer) error {
 for i := 0; i < 10; i++ {
  stream.Send(&hello.HelloResponse{
   Message: fmt.Sprintf("%s %s %d", in.Name, "Reply", i),
  })
 }
 return nil
}
```

编写server入口函数

```golang
package main

import (
 "google.golang.org/grpc"
 "hello/server/controller/hello_controller"
 "hello/server/proto/hello"
 "log"
 "net"
)

const (
 address = "0.0.0.0:9080"
)

func main() {
 listen, err := net.Listen("tcp", address)
 if err != nil {
  log.Fatalf("Failed to listen: %v", err)
 }

 s := grpc.NewServer()

 // 服务注册
 hello.RegisterHelloServer(s, &hello_controller.HelloController{})

 log.Println("Listen on " + address)

 if err := s.Serve(listen); err != nil {
  log.Fatalf("Failed to serve: %v", err)
 }
}
```

编写客户端请求接口的代码

```golang
package main

import (
 "context"
 "google.golang.org/grpc"
 "hello/client/proto/hello"
 "io"
 "log"
)

const (
 address = "0.0.0.0:9080" // grpc服务地址
)

func main() {
 conn, err := grpc.Dial(address, grpc.WithInsecure())
 if err != nil {
  log.Fatalf("Failed to dial: %v", err)
 }
 defer conn.Close()

 // 初始化客户端
 c := hello.NewHelloClient(conn)

 // 调用SyaHello方法
 res, err := c.SayHello(context.Background(), &hello.HelloRequest{
  Name: "Hello World",
 })
 if err != nil {
  log.Fatalf("Failed to SayHello: %v", err)
 }
 log.Println(res.Message)

 // 调用LotsOfReplies方法
 stream, err := c.LotsOfReplies(context.Background(), &hello.HelloRequest{
  Name: "Hello World",
 })
 if err != nil {
  log.Fatalf("Failed to LotsOfReplies: %v", err)
 }

 for {
  res, err := stream.Recv()
  if err == io.EOF {
   break
  }
  if err != nil {
   log.Printf("stream.Recv: %v", err)
  }
  log.Println(res.Message)
 }
}
```

启动服务端和客户端

```perl
pangjiping@pangjipingdeMacBook-Pro hello % cd server     
pangjiping@pangjipingdeMacBook-Pro server % go run main.go
2022/11/11 15:00:14 Listen on 0.0.0.0:9080
```

```perl
pangjiping@pangjipingdeMacBook-Pro hello % cd client 
pangjiping@pangjipingdeMacBook-Pro client % go run main.go 
2022/11/11 14:24:20 Hello World
2022/11/11 14:24:20 Hello World Reply 0
2022/11/11 14:24:20 Hello World Reply 1
2022/11/11 14:24:20 Hello World Reply 2
2022/11/11 14:24:20 Hello World Reply 3
2022/11/11 14:24:20 Hello World Reply 4
2022/11/11 14:24:20 Hello World Reply 5
2022/11/11 14:24:20 Hello World Reply 6
2022/11/11 14:24:20 Hello World Reply 7
2022/11/11 14:24:20 Hello World Reply 8
2022/11/11 14:24:20 Hello World Reply 9
```

<br>
