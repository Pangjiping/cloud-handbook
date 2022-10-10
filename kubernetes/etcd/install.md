<p>&nbsp;</p>
<p>1. 首先应该下载etcd的linux版本，并将压缩包传输到阿里云服务器上&nbsp;https://github.com/etcd-io/etcd/releases</p>
<p>&nbsp;</p>
<p>2. 简单说一下sftp的从本机传输到远程服务器的指令</p>
<div class="cnblogs_code">
<pre><code>lcd /Users/xxx/Downloads</code></pre>
<pre><code>put etcd-v3.5.2-linux-amd64.tar.gz /root</code></pre>
</div>
<p>&nbsp;</p>
<p>3. 连接到服务器，进入root解压etcd安装文件</p>
<div class="cnblogs_code">
<pre><code>tar -zxvf etcd-v3.5.2-linux-amd64.tar.gz</code></pre>
</div>
<p>&nbsp;</p>
<p>4. 进入解压目录，开启etcd后台服务</p>
<div class="cnblogs_code">
<pre><code>nohup ./etcd --listen-client-urls 'http://0.0.0.0:2379' --advertise-client-urls 'http://0.0.0.0:2379'  &amp;</code></pre>
</div>
<p>对公网开启了端口号2379，只是为了测试使用，实际上etcd不应该对公网暴露端口号</p>
<p>&nbsp;</p>
<p>5. 检查etcd是否正常开启</p>
<div class="cnblogs_code">
<pre><code>less nohup.out</code></pre>
</div>
<p>&nbsp;</p>
<p>6. 一些关于key-value的简单操作</p>
<div class="cnblogs_code">
<pre><code>./etcdctl put "name" "own"
./etcdctl get "name"</code></pre>
</div>
<p>&nbsp;</p>
<p>因为etcd中的key是有序的，所以我们可以构建一个抽象的目录结构，来管理项目</p>
<div class="cnblogs_code">
<pre><code>./etcdctl put "myjob/cronjobs/job1" "{job1's json}"
./etcdctl put "myjob/cronjobs/job2" "{job2's json}"</code></pre>
</div>
<p>&nbsp;</p>
<p>同时可以另起一个工作台，watch myjob/cronjobs/这个前缀，实时跟踪定时任务的变化</p>
<div class="cnblogs_code">
<pre><code>./etcdctl watch --prefix "myjob/cronjobs/"</code></pre>
</div>
<p>&nbsp;</p>
<p>我们修改一下job1的value（在任务调度里可以认为是修改了任务的配置文件等），只要我们在job开启etcd的watch，就可以实时监控到对应的value的变化</p>
<div class="cnblogs_code">
<pre><code>./etcdctl put "myjob/cronjobs/job1" "{job1's json hello}"</code></pre>
</div>
<p>&nbsp;</p>
<p>watch到如下修改</p>
<div class="cnblogs_code">
<pre><code>root@xxxx:~/etcd-v3.5.2-linux-amd64# ./etcdctl watch --prefix "myjob/cronjobs/"
PUT
myjob/cronjobs/job1
{job1's json hello}</code></pre>
</div>
<p>&nbsp;</p>
<p>&nbsp;7.golang使用etcd客户端</p>
<p>首先需要安装v3版本的客户端，包很大，运气好的话才能down下来</p>
<div class="cnblogs_code">
<pre><code>go get go.etcd.io/etcd/client/v3</code></pre>
</div>
<p>&nbsp;</p>
<p>配置客户端并建立连接</p>
<pre class="language-go"><code>func main() {
	config := clientv3.Config{
		Endpoints:   []string{":2379"},
		DialTimeout: 5 * time.Second,
	}

	// 建立连接
	client, err := clientv3.New(config)
	if err != nil {
		fmt.Println(err)
		return
	}

}</code></pre>
<p>其中可以Endpoints是一个string类型的切片，etcd客户端是支持高可用的</p>
<p>&nbsp;</p>
<p>我还在go get中...&nbsp;</p>
<p>&nbsp;</p>