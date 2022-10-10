<p><span style="font-size: 14pt;"><strong>1. 制作镜像</strong></span></p>
<p>首先在项目目录下编写Dockerfile</p>

```dockerfile
# Build stage
FROM golang:1.17-alpine3.13 AS builder
WORKDIR /app
COPY . .
RUN go build -o main main.go

# Run stage
FROM alpine:3.13
WORKDIR /app
COPY --from=builder /app/main .
COPY app.env .
EXPOSE 8080
CMD [ "/app/main" ]
```

<p>&nbsp;</p>
<p>终端进入Dockerfile文件目录，执行以下命令</p>
<pre class="language-bash"><code>docker build -t bankdemo:v1 .</code></pre>
<p>&nbsp;</p>
<p>如果项目中引用了大量来自golang/x的包，那么很有可能制作镜像失败，因为无法直接访问，可以挂个全局的梯子试试</p>
<p>生成镜像之后，使用docker images命令查看生成的镜像</p>
<p>在本地尝试我们生成的镜像是否可以正常使用</p>
<pre class="language-bash"><code>docker run --name simplebank -p 8080:8080 -e GIN_MODE=release simplebank</code></pre>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">2. 如何将两个容器部署在同一个网络中</span></strong></p>
<p>我们在编写项目的时候，为了调试代码，很有可能数据库等中间件会部署在localhost，但是当我们生成项目镜像发布的时候项目容器和数据库容器是隔离的，因此我们无法在项目中使用localhost访问数据库，简单的做法是修改配置文件中的数据库uri，然后重新制作镜像，但是面临的问题是数据库每次发生修改，我们都要修改相对应的配置文件，然后重启容器。</p>
<p>了解一下如何在docker中将两个容器部署在同一个network中</p>
<p>&nbsp;</p>
<p>使用docker network ls命令可以看到目前容器中的默认网桥</p>
<pre class="language-bash"><code>docker network ls

##################################
NETWORK ID     NAME      DRIVER    SCOPE
b5987a259877   bridge    bridge    local
307e0dd8195b   host      host      local
240c3ae5bf5c   none      null      local</code></pre>
<p>&nbsp;</p>
<p>使用docker network inspect bridge可以看到在这个网络上运行的所有容器列表</p>
<pre class="language-bash"><code>docker network inspect bridge

##################################
        "Containers": {
            "05cfed554b6db9b05ac971cd45f6bae0629d07502446bcda7def6165c50bbae3": {
                "Name": "modest_visvesvaraya",
                "EndpointID": "88c7fe42e7f163e722dd9090804b33183a4480272ea887a014daf98de8bf6f7b",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },</code></pre>
<p>&nbsp;</p>
<p>通常运行在同一个网络中的容器都可以用名称来发现对方，但这不适用于默认网桥，所以我们需要自己创建一个网络，让我们的服务和数据库连接到这个网络中</p>
<p>使用docker network create创建一个新的网络</p>
<pre class="language-bash"><code>docker network create test-network</code></pre>
<p>&nbsp;</p>
<p>使用docker network connect将正在运行的数据库连接到我们创建的test-network中</p>
<pre class="language-bash"><code>docker network connect test-network postgres</code></pre>
<p>&nbsp;</p>
<p>如果我们这时再去查看test-network中的容器的话，就会发现postgres已经连接到了这个新的网络</p>
<pre class="language-bash"><code>docker network inspect test-network</code></pre>
<p>&nbsp;</p>
<p>同样如果我们查看postgres容器的信息，会发现postgres已经连接到了两个网络中：bridge test-network</p>
<pre class="language-bash"><code>docker container inspect postgres</code></pre>
<p>&nbsp;</p>
<p>然后让我们重新运行服务容器，连接到test-network，注意此时应该把配置信息中的postgres连接uri从loaclhost换成postgres（对应的容器名）</p>
<pre class="language-bash"><code>docker run --name simplebank --network test-network -p 8080:8080 -g GIN_MODE=release simplebank:latest</code></pre>
<p>&nbsp;</p>
<p>使用postman检查服务是否正常</p>