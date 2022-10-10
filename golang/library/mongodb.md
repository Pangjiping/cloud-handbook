<p><span style="font-size: 14pt;"><strong>go客户端实现mongoDB的增删改查</strong></span></p>
<p>&nbsp;所有api的使用和说明都在官方文档：&nbsp;https://pkg.go.dev/go.mongodb.org/mongo-driver/mongo#pkg-index</p>
<p>下面只记录一下项目中用到的简单的增删改查操作</p>
<p>&nbsp;</p>
<p>可能用过mysql和redis客户端的不太习惯mongo客户端的操作，它获取一个表操作对象分成了几个部分：获取客户端连接、选择数据库、选择表</p>

```golang
// 建立连接
client, err := mongo.Connect(context.TODO(),
    options.Client().ApplyURI("mongodb://xxx.xxx.xxx.xxx:27017"),
    options.Client().SetConnectTimeout(5*time.Second))
if err != nil {
    fmt.Println(err)
    return
}

// 选择数据库
database := client.Database("cron")

// 选择表log
collection := database.Collection("log")
```
<p>&nbsp;</p>
<p>因为mongo中数据是使用bson格式存储的，所以在定义插入数据结构体时，需要使用bson标签进行反射</p>

```golang
// 任务的执行时间点
type TimePoint struct {
    StartTime int64 `bson:"startTime"`
    EndTime   int64 `bson:"endTime"`
}

// 日志结构
type logRecord struct {
    JobName   string    `bson:"jon_name"`  //任务名
    Command   string    `bson:"commond"`   // shell命令
    Err       string    `bson:"err"`       // 脚本错误
    Content   string    `bson:"content"`   //脚本输出
    TimePoint TimePoint `bson:"timePoint"` //执行时间
}
```
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>1. 向mongoDB中插入数据</strong></span></p>
<p>插入数据是对我们获取到的表操作对象进行的，具体的插入函数签名有如下几个：</p>

```golang
func (coll *Collection) InsertMany(ctx context.Context, documents []interface{}, ...) (*InsertManyResult, error)
func (coll *Collection) InsertOne(ctx context.Context, document interface{}, opts ...*options.InsertOneOptions) (*InsertOneResult, error)
```

<p>&nbsp;</p>
<p>根据函数名可以看出可以选择插入一个和多个，opt是<a href="https://pkg.go.dev/go.mongodb.org/mongo-driver@v1.8.4/mongo/options">options</a>.<a href="https://pkg.go.dev/go.mongodb.org/mongo-driver@v1.8.4/mongo/options#InsertOneOptions">InsertOneOptions</a>结构体指针，里面有可选择的参数</p>
<p>向mongo中插入一个任务日志：</p>

```golang
// 定义数据结构体
record := &amp;logRecord{
    JobName: "job10",
    Command: "ceho hello",
    Err:     "",
    Content: "hello",
    TimePoint: TimePoint{
        StartTime: time.Now().Unix(),
        EndTime:   time.Now().Unix() + 10,
    },
}

// 插入数据
insertOneResult, err := collection.InsertOne(context.TODO(), record)
if err != nil {
    fmt.Println(err)
    return
}

// 默认生成一个全局唯一的id，12字节的二进制
docID := insertOneResult.InsertedID.(primitive.ObjectID)
fmt.Println("自增ID：", docID.Hex())
```
<p>&nbsp;</p>
<p>注意insertOneResult只有InsertID这一个属性，是一个12字节的二进制，如果想要变成易读数据格式需要进行类型断言，并且使用.Hex()方法来转换</p>
<p>插入多条数据也是一样的操作，需要先声明一个插入数据的切片</p>

```golang
// 批量插入多条数据
logArr := []interface{}{record, record, record}

insertManyResult, err := collection.InsertMany(context.TODO(), logArr)
if err != nil {
    fmt.Println(err)
    return
}
for _, id := range insertManyResult.InsertedIDs {
    docID := id.(primitive.ObjectID)
    fmt.Println("自增ID:", docID.Hex())
}
```
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>2. 从mongoDB中读取数据</strong></span></p>
<p>首先来看一下查找数据的函数签名，有很多，大抵就是查找和更新删除等操作的组合，其参数列表里有一个 filter过滤器，这个需要自己定义过滤器，来指明我们需要针对什么条件来查询，opts仍然是可选参数，findopt就有很多，分页limit排序等等，如果需要的话可以看看各个参数的释义。</p>

```golang
func (coll *Collection) Find(ctx context.Context, filter interface{}, opts ...*options.FindOptions) (*Cursor, error)
func (coll *Collection) FindOne(ctx context.Context, filter interface{}, opts ...*options.FindOneOptions) *SingleResult
func (coll *Collection) FindOneAndDelete(ctx context.Context, filter interface{}, ...) *SingleResult
func (coll *Collection) FindOneAndReplace(ctx context.Context, filter interface{}, replacement interface{}, ...) *SingleResult
func (coll *Collection) FindOneAndUpdate(ctx context.Context, filter interface{}, update interface{}, ...) *SingleResult
```
<p>&nbsp;</p>
<p>首先定义一个简单的过滤器：</p>

```golang
// jobname过滤条件
type FindByJobName struct {
    JobName string `bson:"jon_name"`
}

// 按照jobname过滤，找出jobname=job10
cond := &amp;FindByJobName{
    JobName: "job10",
}
```
<p>&nbsp;</p>
<p>执行find，返回的是一个*mongo.Cursor类型的值，就是一个游标，类似于mysql中的游标，之后我们可以使用这个游标遍历结果集</p>

```golang
skip := int64(0)
limit := int64(2)
// 查询
//cursor, err := collection.Find(context.TODO(), bson.D{{"jon_name", "job10"}}) // 这是官方案例中的写法，显得不像在写客户端
cursor, err := collection.Find(context.TODO(), cond, &amp;options.FindOptions{
    Skip:  &amp;skip,
    Limit: &amp;limit,
})
defer cursor.Close(context.TODO())
if err != nil {
    fmt.Println(err)
    return
}
```
<p>&nbsp;</p>
<p>遍历结果集，得到查询到的数据</p>

```golang
// 遍历结果集
for cursor.Next(context.TODO()) {
    record := &amp;logRecord{}

    // 反序列化bson到结构体对象
    err := cursor.Decode(record)
    if err != nil {
        fmt.Println(err)
        return
    }

    // 打印结构体
    fmt.Println(*record)
}
```
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>3. 删除mongoDB中的数据</strong></span></p>
<p>首先定义一个删除规则：我们要删除创建时间小于当前时间的日志，等同于清空数据库了。</p>
<p>先来看看删除的函数签名，其实和find是类似的，需要一个过滤器</p>

```golang
func (coll *Collection) DeleteMany(ctx context.Context, filter interface{}, opts ...*options.DeleteOptions) (*DeleteResult, error)
func (coll *Collection) DeleteOne(ctx context.Context, filter interface{}, opts ...*options.DeleteOptions) (*DeleteResult, error)
```
<p>&nbsp;</p>
<p>根据删除规则我们定义一个过滤器，我们要删除的是创建时间小于当前时间的，那么在mongo ctl中就应该写成json表达式</p>
<p>delete({"timePoint.startPoint":{"$lt":当前时间}})</p>
<p>我们可以利用go的bson反射来做到这个表达式的定义，记住反射是怎么序列化的就行，后面的bson标签是key</p>

```golang
// startTime小于某时间
// {"$lt":timestamp}
type TimeBeforeCond struct {
    Before int64 `bson:"$lt"`
}

// 定义删除条件
// {"timePoint.startPoint":{"$lt":timestamp}}
type DelCond struct {
    beforeCond TimeBeforeCond `bson:"timePoint.startTime"`
}
```
<p>&nbsp;</p>
<p>现在让我们执行deletemany操作，返回的*mongo.DeleteResult只有一个属性就是被删除了多少行</p>

```golang
// 定义删除条件
delCond := &amp;DelCond{
    beforeCond: TimeBeforeCond{
        Before: time.Now().Unix(),
    },
}

deleteResult, err := collection.DeleteMany(context.TODO(), delCond)
if err != nil {
    fmt.Println(err)
    return
}
fmt.Println("删除了多少行：", deleteResult.DeletedCount)
```
<p>&nbsp;</p>
<p>以上只是一些go-mongo客户端的简单操作，如果有更复杂的需求建议去阅读官方文档，里面有每个方法的详细释义及example</p>
<p>&nbsp;</p>