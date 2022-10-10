<p>golang-etcd客户端操作</p>
<p>关于golang-etcd的所有api介绍和使用demo，可以参见&nbsp;https://pkg.go.dev/go.etcd.io/etcd/client/v3#pkg-overview</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>1. 获取客户端连接</strong></span></p>

```golang
func main() {
    config := clientv3.Config{
        Endpoints:   []string{"xxx.xxx.xxx.xxx:2379"},
        DialTimeout: 5 * time.Second,
    }

    // 获取客户端连接
    _, err := clientv3.New(config)
    if err != nil {
        fmt.Println(err)
        return
    }
}
```
<p>&nbsp;</p>
<p>clientv3.Config包含的常用配置信息及其释义如下：</p>
<table style="height: 297px; width: 782px;" border="1" align="center">
<tbody>
<tr>
<td>
<div>Endpoints</div>
</td>
<td>
<div>[]string</div>
</td>
<td>etcd集群ip+port</td>
</tr>
<tr>
<td>
<div>DialTimeout</div>
</td>
<td>
<div>time.Duration</div>
</td>
<td>连接超时时间</td>
</tr>
<tr>
<td>
<div>
<div>DialKeepAliveTimeout</div>
</div>
</td>
<td>
<div>time.Duration</div>
</td>
<td>客户端keepalive超时时间</td>
</tr>
<tr>
<td>
<div>
<div>DialKeepAliveTime</div>
</div>
</td>
<td>
<div>time.Duration</div>
</td>
<td>查看是否正常服务</td>
</tr>
<tr>
<td>
<div>
<div>
<div>MaxCallSendMsgSize</div>
</div>
</div>
</td>
<td>int</td>
<td>客户端请求的最大字节限制，默认2MiB</td>
</tr>
<tr>
<td>
<div>
<div>
<div>
<div>MaxCallRecvMsgSize</div>
</div>
</div>
</div>
</td>
<td>int</td>
<td>客户端响应的最大字节限制，默认math.MaxInt32</td>
</tr>
<tr>
<td>
<div>
<div>
<div>
<div>
<div>Username</div>
</div>
</div>
</div>
</div>
</td>
<td>string</td>
<td>用户名</td>
</tr>
<tr>
<td>Password</td>
<td>string</td>
<td>密码</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">2. PUT操作</span></strong></p>

```golang
// 用于写etcd的键值对
kv := clientv3.NewKV(client)

// PUT请求，clientv3.WithPrevKV()表示获取上一个版本的kv
putResp, err := kv.Put(context.TODO(), "/cron/jobs/job1", "hello",clientv3.WithPrevKV())
if err != nil {
    fmt.Println(err)
    return
}
// 获取版本号
fmt.Println("Revision:", putResp.Header.Revision)
// 如果有上一个kv 返回kv的值
if putResp.PrevKv != nil {
    fmt.Println("PrevValue:", string(putResp.PrevKv.Value))
}
```

<p>kv.Put()参数列表解释：</p>
<ul>
<li>第一个参数为context，可以自己设置可取消和自动过期的context</li>
<li>第二个参数为key</li>
<li>第三个参数为value</li>
<li>后面的参数可选，with开头，支持多种功能，具体可以参考所有with的文档</li>
</ul>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">3. GET操作</span></strong></p>

```golang
// 用于读写etcd的键值对
kv := clientv3.NewKV(client)

// 简单的get操作
getResp, err := kv.Get(context.TODO(), "cron/jobs/job1", clientv3.WithCountOnly())
if err != nil {
    fmt.Println(err)
    return
}
fmt.Println(getResp.Count)
```

<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">4. DELETE操作</span></strong></p>

```golang
// 用于写etcd的键值对
kv := clientv3.NewKV(client)

// 读取cron/jobs下的所有key
getResp, err := kv.Get(context.TODO(), "/cron/jobs", clientv3.WithPrefix())
if err != nil {
    fmt.Println(err)
    return
}

// 获取目录下所有key-value
fmt.Println(getResp.Kvs)
```
<p>&nbsp;</p>

```golang
// 用于读写etcd的键值对
kv := clientv3.NewKV(client)

// 删除指定kv
delResp, err := kv.Delete(context.TODO(), "/cron/jobs/job1", clientv3.WithPrevKV())
if err != nil {
    fmt.Println(err)
    return
}

// 被删除之前的value是什么
if len(delResp.PrevKvs) != 0 {
    for _, kvpair := range delResp.PrevKvs {
        fmt.Println("delete:", string(kvpair.Key), string(kvpair.Value))
    }
}

// 删除目录下的所有key
delResp, err = kv.Delete(context.TODO(), "/cron/jobs/", clientv3.WithPrefix())
if err != nil {
    fmt.Println(err)
    return
}

// 删除从这个key开始的后面的两个key
delResp, err = kv.Delete(context.TODO(), "/cron/jobs/job1",clientv3.WithFromKey(), clientv3.WithLimit(2))
if err != nil {
    fmt.Println(err)
    return
}
```
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">5. watch操作</span></strong></p>

```golang
// 创建一个用于读写的kv
kv := clientv3.NewKV(client)

// 模拟etcd中kv的变化，每隔1s执行一次put-del操作
go func() {
    for {
        kv.Put(context.TODO(), "/cron/jobs/job7", "i am job7")
        kv.Delete(context.TODO(), "/cron/jobs/job7")
        time.Sleep(time.Second * 1)
    }
}()

// 先get到当前的值，并监听后续变化
getResp, err := kv.Get(context.TODO(), "/cron/jobs/job7")
if err != nil {
    fmt.Println(err)
    return
}

// 现在key是存在的
if len(getResp.Kvs) != 0 {
    fmt.Println("当前值：", string(getResp.Kvs[0].Value))
}

// 监听的revision起点
watchStartRevision := getResp.Header.Revision + 1

// 创建一个watcher
watcher := clientv3.NewWatcher(client)

// 启动监听
fmt.Println("从这个版本开始监听：", watchStartRevision)

// 设置5s的watch时间
ctx, cancelFunc := context.WithCancel(context.TODO())
time.AfterFunc(5*time.Second, func() {
        cancelFunc()
})
watchRespChan := watcher.Watch(ctx, "/cron/jobs/job7", clientv3.WithRev(watchStartRevision))

// 得到kv的变化事件，从chan中取值
for watchResp := range watchRespChan {
    for _, event := range watchResp.Events { //.Events是一个切片
        switch event.Type {
        case mvccpb.PUT:
            fmt.Println("修改为：", string(event.Kv.Value),
                    "revision:", event.Kv.CreateRevision, event.Kv.ModRevision)
        case mvccpb.DELETE:
            fmt.Println("删除了：", "revision:", event.Kv.ModRevision)
        }
    }
}
```

<p>watch操作的逻辑也很简单，但是要注意确定从哪个版本开始监听，全部监听是没有意义的</p>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">6. lease</span></strong></p>

```golang
// 用于申请租约
lease := clientv3.NewLease(client)

// 申请一个10s的租约
leaseGrantResp, err := lease.Grant(context.TODO(), 10) //10s
if err != nil {
    fmt.Println(err)
    return
}

// 拿到租约的id
leaseID := leaseGrantResp.ID

// 自动续租
keepRespChan, err := lease.KeepAlive(context.TODO(), leaseID)
if err != nil {
    fmt.Println(err)
    return
}

// 处理续租应答的协程
go func() {
    select {
    case keepResp := &lt;-keepRespChan:
        if keepRespChan == nil {
            fmt.Println("lease has expired")
            goto END
        } else {
            // 每秒会续租一次
            fmt.Println("收到自动续租应答", keepResp.ID)
        }
    }
END:
}()

// 用于读写etcd的键值对
kv := clientv3.NewKV(client)

// put一个key-value，关联租约，实现10s后过期
// 防止程序宕机
putResp, err := kv.Put(context.TODO(), "/cron/lock/job1", "",
        clientv3.WithLease(leaseID))
if err != nil {
    fmt.Println(err)
    return
}
fmt.Println("put success", putResp.Header.Revision)

for {
    getResp, err := kv.Get(context.TODO(), "/cron/lock/job1")
    if err != nil {
        fmt.Println(err)
        return
    }
    if getResp.Count == 0 {
        fmt.Println("key-value is expired")
        return
    } else {
        fmt.Println(getResp.Kvs)
        time.Sleep(2 * time.Second)
    }
}
```
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>7. operator</strong></span></p>
<p>operator和普通的put、get等方法类似，有点像mysql里面的prepare，又封装了一层，在实现etcd分布式锁的时候有一些帮助</p>

```golang
kv := clientv3.NewKV(client)

// 创建putop
putOp := clientv3.OpPut("/cron/jobs/job7", "")

// 执行op
opResp, err := kv.Do(context.TODO(), putOp)
if err != nil {
    fmt.Println(err)
    return
}

fmt.Println("写入的revision：", opResp.Put().Header.Revision)

// 创建getOp
getOp := clientv3.OpGet("/cron/jobs/job7")

// 执行op
getResp, err := kv.Do(context.TODO(), getOp)
if err != nil {
    fmt.Println(err)
    return
}
fmt.Println("revision：", getResp.Get().Kvs[0].ModRevision)
fmt.Println("取到的值为：", getResp.Get().Kvs[0].Value)
```

<p>&nbsp;</p>