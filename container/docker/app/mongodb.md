<p><span style="font-size: 14pt;"><strong>1. mongoDB功能介绍</strong></span></p>
<p>1.1 核心特性</p>
<ul>
<li>文档数据库，基于二进制json存储文档</li>
<li>高性能、高可用、直接加机器就可以解决扩展性问题</li>
<li>支持丰富的CRUD操作，例如聚合统计、全文检索、坐标检索</li>
</ul>
<p>1.2 文档数据库</p>
<p>存放的是json格式的数据，任何字段都不需要提前定义</p>
<pre class="language-json"><code>{
  name:"pp",
  age:23,
  status:"working",
  groups:["news","sports"]            
}</code></pre>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">2. mongoDB架构</span></strong>&nbsp;</p>
<p>&nbsp;</p>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220316202400169-1079864081.png" alt="" width="735" height="362" loading="lazy" /></p>
<p>&nbsp;</p>
<p>存储引擎是数据库和硬件之间的接口，它负责处理用什么数据结构存储数据，以及如何写入、删除和读取数据。不同的工作负载类型对于读写性能的需求不同，例如新闻网站需要大量的读，而社交类网站需要大量的写。MongoDB 3.0开始，提供了可插拔的存储引擎API，使得用户可以在MongoDB和第三方提供的多种存储引擎之间切换。</p>
<p>在一个MongoDB复制集中，多种存储引擎可以并存，可以满足应用更复杂的需求。例如，使用In-memory存储引擎进行低延时的操作，同时使用基于磁盘的存储引擎完成持久化。</p>
<p>目前MongoDB默认使用的是WiredTiger存储引擎，WiredTiger是SleepyCat提供的一款开源数据引擎。通过使用现代编程技术，如Hazard指针和Lock-free算法，WiredTiger实现了多核可扩展性。</p>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">3. mongoDB简单用法示例</span></strong></p>
<ul>
<li>列举数据库：show databases</li>
<li>选择数据库：use my_db1&nbsp; --数据库无需创建，只是一个命名空间</li>
<li>列举数据表：show collectons</li>
<li>建立数据表：db.createCollection("my_collection")&nbsp; --数据表schema free，无需定义字段</li>
<li>插入document：db.my_collection.insertOne({uid:10000,name:"xiaoming",likes:["football","game"]})&nbsp; --任意嵌套层级的json，文档ID自动生成，无需指定</li>
<li>查询document：db.my_collection.find({likes:'football',name:{$in:['xiaoming','libai']}}).sort({uid:1})&nbsp; --基于任意json层级过滤</li>
<li>更新document：db.my_collection.updateMany({likes:'football'},{$set:{name:'libai'}})&nbsp; --第一个参数是过滤条件，第二个参数是更新操作</li>
<li>删除document：db.my_collection.deleteMany({name:'xiaoming'})&nbsp; --参数是过滤条件</li>
<li>创建index：db.my_collection.createIndex({uid:1, name:-1})&nbsp; --可以指定创建索引时的正反顺序，影响排序效率</li>
</ul>
<p>所有操作示例见官方文档：https://docs.mongodb.com/manual/crud/</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">4. mongoDB单机安装</span></strong></p>
<p>&nbsp;推荐使用docker安装单机mongoDB，主要是方便...docker search mongo #搜索mongo镜像，如果没有特殊需求建议选择官方版</p>
<pre class="language-bash"><code>#搜索mongo镜像，如果没有特殊需求建议选择官方版
docker search mongo 

#不加tag默认拉取最新镜像
docker pull mongo

#查看镜像是否拉取成功
docker images

#暴露27017端口，连接客户端，同时可以-v 选择挂载volume
docker run -itd --name mongo -p 27017:27017 mongo 

#查看mongo服务是否已经启动
docker ps

#进入mongo容器
docker exec -it mongo mongo admin

#新增admin用户，密码123456
db.createUser({ user:'admin',pwd:'123456',roles:[ { role:'userAdminAnyDatabase', db: 'admin'},"readWriteAnyDatabase"]});

#admin用户登录mongo
db.auth('admin','123456')</code></pre>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">5. 客户端连接mongoDB</span></strong></p>
<p>首先需要install客户端</p>
<pre class="language-bash"><code>go get go.mongodb.org/mongo-driver/mongo</code></pre>
<p>&nbsp;</p>
<p>go-mongo详细的api文档可以看官网文档，有很详细的example</p>
<p>https://pkg.go.dev/go.mongodb.org/mongo-driver@v1.8.0/mongo#pkg-overview</p>

```golang
func main() {
    // 建立连接 5s超时
    client, err := mongo.Connect(context.TODO(),
        options.Client().ApplyURI("mongodb://xxx.xxx.xxx.xxx:27017"),
        options.Client().SetConnectTimeout(time.Second*5))
    if err != nil {
        fmt.Println(err)
        return
    }

    // 选择数据库
    database := client.Database("my_db")

    // 选择表
    collection := database.Collection("my_collection")
    collection = collection
}
```