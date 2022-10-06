<p>在高并发场景中，通常需要像mysql中那样的自增主键一样的不会重复且自增的id生成</p>
<p>twitter的snowflake就是一种典型的解法，id数值长64位，是一个int64类型，被分为四个部分：</p>
<ul>
<li>最高位不使用</li>
<li>41位表示收到请求的时间戳，单位为毫秒</li>
<li>5位表示数据中心的id</li>
<li>5位表示机器实例的id</li>
<li>12位循环自增id，1111,1111,1111后归零</li>
</ul>
<p>这样的机制可以保证一台机器在一毫秒内产生4096条消息，一秒总共409.6万条消息</p>
<p>数据中心id配合实例id一共有10位，每个数据中心可以部署32台实例，搭建32个数据中心，所以一共存在1024个实例</p>
<p>41位时间戳可以使用69年</p>
<p>&nbsp;</p>
<h2>1.&nbsp;github.com/bwmarrin/snowflake</h2>
<p>github.com/bwmarrin/snowflake是一个轻量级的snowflake实现</p>
<p>首先需要引入依赖</p>
<pre class="language-bash"><code>go get github.com/bwmarrin/snowflake</code></pre>
<p>&nbsp;</p>
<p>这个库使用起来也非常简单</p>
<pre class="language-go"><code>func main(){
    node,err:=snowflak.NewNode(1)
    if err!=nil{
        println(err.Error())
        os.Exit(1)
    }

    for i:=0;i&lt;20;i++{
        id:=node.Generate()

        fmt.Printf(  "int64 ID: %d\n" ,id)
        fmt.Printf(  "string ID: %s\n" ,id)
        fmt.Printf(  "base2 ID: %s\n" ,id.Base2())
        fmt.Printf(  "base64 ID: %s\n" ,id.Base64())
        fmt.Printf(  "ID time: %d\n" ,id.Time())
        fmt.Printf(  "ID node: %d\n" ,id.Node())
        fmt.Printf(  "ID step: %d\n" ,id.Step())
        fmt.Println(  "--------------------------------" )
    }
}</code></pre>
<p>&nbsp;</p>
<p>这个库是一个单文件，其中提供了我们可以定制的参数</p>
<p>其中Epoch是起始时间、NodeBits是实例id的长度，默认10位、StepBits是自增id的长度，默认12位</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220407213342263-1248115563.png" alt="" width="831" height="488" loading="lazy" /></p>
<p>&nbsp;</p>
<h2>2.&nbsp;github.com/sony/sonyflake</h2>
<p>snoyflake侧重于多主机多实例的生命周期和性能，所以与snowflake使用了不同的位分配：</p>
<ul>
<li>比snowflake更长的生命周期，174年</li>
<li>能运行在更多的实例上，216个</li>
<li>生成id的速度比snowflake慢，10ms内最多生成28个</li>
</ul>
<p>&nbsp;</p>
<p>snoyflake在启动阶段需要配置参数，主要是一个Setting结构体</p>
<pre class="language-go"><code>type Settings  struct {
    StartTime&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; time.Time&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  // 起始时间，默认2014-09-01 00:00:00 +0000 UTC
    MachineID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  func () (uint16, error)  // 返回实例ID的函数，如果不定义此函外，默认用本机ip的低16位
    CheckMachineID  func (uint16) bool&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  // 验证实例ID/计算机ID的唯一性，返回true时才创建
}</code></pre>
<p>&nbsp;</p>
<p>我们需要自己实现这两个函数：</p>
<pre class="language-go"><code>func getMachineID() (uint16, error) {
    var machineID uint16 = 6
    return machineID, nil
}

func checkMachineID(machineID uint16) bool {
    existsMachines := []uint16{1, 2, 3, 4, 5}
    for _, v :=  range existsMachines {
        if v == machineID {
            return false
        }
    }
    return true
}
</code></pre>
<p>&nbsp;</p>
<pre class="language-go"><code>func main() {
    t, _ := time.Parse( "2006-01-02" ,  "2021-01-01" )
    settings := sonyflake.Settings{
        StartTime:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; t,
        MachineID:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; getMachineID,
        CheckMachineID: checkMachineID,
    }

    sf := sonyflake.NewSonyflake(settings)

    for i := 0; i &lt; 10; i++ {
        id, err := sf.NextID()
        if err != nil {
            fmt.Println(err)
            os.Exit(1)
        }
        fmt.Println(id)
    }
}</code></pre>
<p>&nbsp;</p>