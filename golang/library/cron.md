<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>1. cron表达式的基本格式</strong></span></p>
<p>cron表达式是一个字符串，字符串以5或6个空格隔开，分为6或7个域，每一个域代表一个含义，cron有如下两种语法格式：</p>
<ul>
<li>second minute hour dayofmonth month dayofweek year</li>
<li>second minute hour dayofmonth month dayofweek</li>
</ul>
<p>&nbsp;</p>
<p>各个字段的含义</p>
<table style="height: 349px; width: 728px;" border="0" align="center">
<tbody>
<tr>
<td>字段</td>
<td>允许值</td>
<td>允许的特殊字符</td>
</tr>
<tr>
<td>秒(second)</td>
<td>0-59整数</td>
<td>, - * /</td>
</tr>
<tr>
<td>分(minute)</td>
<td>0-59整数</td>
<td>, - * /</td>
</tr>
<tr>
<td>时(hour)</td>
<td>0-23整数</td>
<td>, - * /</td>
</tr>
<tr>
<td>日期(day of month)</td>
<td>1-31整数（但要考虑月份的天数）</td>
<td>, - * ? / L W C&nbsp;</td>
</tr>
<tr>
<td>月份(month)</td>
<td>1-13整数或者 JAN-DEC</td>
<td>, - * /</td>
</tr>
<tr>
<td>星期(day of week)</td>
<td>1-7整数或者 SUN-SAT (SUN=1)</td>
<td>, - * ? / L C #</td>
</tr>
<tr>
<td>年(year)</td>
<td>1970-2099</td>
<td>, - * /</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p>特殊字符释义：</p>
<ul>
<li>*：表示匹配该域的任意值。假如在Minutes域使用*, 即表示每分钟都会触发事件。</li>
<li>?：只能用在DayofMonth和DayofWeek两个域。它也匹配域的任意值，但实际不会。因为DayofMonth和DayofWeek会相互影响。例如想在每月的20日触发调度，不管20日到底是星期几，则只能使用如下写法： 13 13 15 20 * ?, 其中最后一位只能用？，而不能使用*，如果使用*表示不管星期几都会触发，实际上并不是这样。</li>
<li>-：表示范围。例如在Minutes域使用5-20，表示从5分到20分钟每分钟触发一次&nbsp;</li>
<li>/：表示起始时间开始触发，然后每隔固定时间触发一次。例如在Minutes域使用5/20,则意味着5分钟触发一次，而25，45等分别触发一次.</li>
<li>,：表示列出枚举值。例如：在Minutes域使用5,20，则意味着在5和20分每分钟触发一次。&nbsp;</li>
<li>L：表示最后，只能出现在DayofWeek和DayofMonth域。如果在DayofWeek域使用5L,意味着在最后的一个星期四触发。</li>
<li>W:表示有效工作日(周一到周五),只能出现在DayofMonth域，系统将在离指定日期的最近的有效工作日触发事件。例如：在 DayofMonth使用5W，如果5日是星期六，则将在最近的工作日：星期五，即4日触发。如果5日是星期天，则在6日(周一)触发；如果5日在星期一到星期五中的一天，则就在5日触发。另外一点，W的最近寻找不会跨过月份 。</li>
<li>LW:这两个字符可以连用，表示在某个月最后一个工作日，即最后一个星期五。</li>
<li>#:用于确定每个月第几个星期几，只能出现在DayofMonth域。例如在4#2，表示某月的第二个星期三。</li>
</ul>
<p>&nbsp;</p>
<p>常用的cron表达式例子：</p>
<ul>
<li><strong>0 0 2 1 * ? *</strong>&nbsp;&nbsp;&nbsp;表示在每月的1日的凌晨2点调整任务</li>
<li><strong>0 15 10 ? * MON-FRI&nbsp;</strong>&nbsp; 表示周一到周五每天上午10:15执行作业</li>
<li><strong>0 0 10,14,16 * * ?</strong>&nbsp;&nbsp;&nbsp;每天上午10点，下午2点，4点&nbsp;</li>
<li><strong>0 0/30 9-17 * * ?</strong>&nbsp;&nbsp; 朝九晚五工作时间内每半小时</li>
<li><strong>0 15 10 ? * * &nbsp;</strong>&nbsp;&nbsp;每天上午10:15触发</li>
<li><strong><strong>0 15 10 L * ?&nbsp;</strong>&nbsp; &nbsp;</strong>每月最后一日的上午10:15触发</li>
</ul>
<p>&nbsp;</p>
<p><strong><span style="font-size: 14pt;">2. go解析cron表达式</span></strong></p>
<p>首先需要引入依赖：</p>
<pre class="language-bash"><code>go get github.com/gorhill/cronexpr</code></pre>
<p>&nbsp;</p>

```golang
func main() {
    // 每分钟执行一次
    _, err := cronexpr.Parse("* * * * *")
    if err != nil {
        fmt.Println(err)
        return
    }

    // 每隔5s执行一次
    expr, err := cronexpr.Parse("*/5 * * * * * *")
    if err != nil {
        fmt.Println(err)
        return
    }

    // 当前时间
    now := time.Now()

    // 获取下次调度的时间
    nextTime := expr.Next(now)

    // 等待这个定时器超时
    time.AfterFunc(nextTime.Sub(now), func() {
        fmt.Println("被调度了", nextTime)
    })

    time.Sleep(time.Second * 20)
}
```
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>3. 通过cron表达式实现一个简单定时任务调度</strong></span></p>
<p>实现一个简单的任务调度必然需要一个调度协程，定时检查所有cron任务，过期就会被执行</p>

```golang
type CronJob struct {
    expr     *cronexpr.Expression
    nextTime time.Time // expr.next(now)
}

func main() {
    now := time.Now()

    // 创建一个调度表 key:任务的名字
    scheduleTable := make(map[string]*CronJob)

    // 定义cronjob
    expr := cronexpr.MustParse("*/5 * * * * * *")
    cronJob := &amp;CronJob{
        expr:     expr,
        nextTime: expr.Next(now),
    }
    // 把任务注册到调度表
    scheduleTable["job1"] = cronJob

    // 定义cronjob
    expr = cronexpr.MustParse("*/5 * * * * * *")
    cronJob = &amp;CronJob{
        expr:     expr,
        nextTime: expr.Next(now),
    }
    // 把任务注册到调度表
    scheduleTable["job2"] = cronJob

    // 现在有两个5s的定时任务了

    // 启动一个调度协程
    go func() {
        var (
            jobName string
            cronJob *CronJob
        )
        // 定时检查任务调度表
        for {
            now = time.Now()
            for jobName, cronJob = range scheduleTable {

                // 判断是否过期
                if cronJob.nextTime.Before(now) || cronJob.nextTime.Equal(now) {

                    // 启动一个协程执行这个任务
                    go func(jobName string) {
                        fmt.Println("执行", jobName)
                    }(jobName)

                    // 计算下一次的调度时间
                    cronJob.nextTime = cronJob.expr.Next(now)
                    fmt.Println("下次执行时间：", cronJob.nextTime)
                }
            }

            // 睡眠100ms
            select {
            case &lt;-time.NewTimer(100 * time.Millisecond).C:
            }
        }
    }()

    time.Sleep(100 * time.Second)
}
```