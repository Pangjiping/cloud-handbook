<h1>1. session模块</h1>
<p>beego内置了sesson模块，目前session模块支持的后端引擎包括了memory、cookie、file、mysql、redis、couchbase、memcache、postgres，用户可以根据相应的interface来实现自己的引擎</p>
<p>beego中使用session相当方便，只要在main入口函数中设置如下：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionOn = true</code></pre>
<p>&nbsp;</p>
<p>或者通过配置文件如下：</p>
<pre class="language-go"><code>sessionon = true</code></pre>
<p>&nbsp;</p>
<p>通过这种方式就可以开启session，如何使用session，请看下面的例子：</p>
<pre class="language-go"><code>func (this *MainController) Get() {
	v := this.GetSession("asta")
	if v == nil {
		this.SetSession("asta", int(1))
		this.Data["num"] = 0
	} else {
		this.SetSession("asta", v.(int)+1)
		this.Data["num"] = v.(int)
	}
	this.TplName = "index.tpl"
}</code></pre>
<p>&nbsp;</p>
<p>session有几个方便的方法：</p>
<ul>
<li>SetSession(name string, value interface{})</li>
<li>GetSession(name string) interface{}</li>
<li>DelSession(name string)</li>
<li>SessionRegenerateID()</li>
<li>DestroySession()</li>
</ul>
<p>&nbsp;</p>
<p>关于session模块中使用的一些参数设置：</p>
<ul>
<li>
<p>web.BConfig.WebConfig.Session.SessionOn</p>
<p>设置是否开启 Session，默认是 false，配置文件对应的参数名：sessionon。</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionProvider</p>
<p>设置 Session 的引擎，默认是 memory，目前支持还有 file、mysql、redis 等，配置文件对应的参数名：sessionprovider。</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionName</p>
<p>设置 cookies 的名字，Session 默认是保存在用户的浏览器 cookies 里面的，默认名是 beegosessionID，配置文件对应的参数名是：sessionname。</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionGCMaxLifetime</p>
<p>设置 Session 过期的时间，默认值是 3600 秒，配置文件对应的参数：sessiongcmaxlifetime。</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionProviderConfig</p>
<p>设置对应 file、mysql、redis 引擎的保存路径或者链接地址，默认值是空，配置文件对应的参数：sessionproviderconfig。</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionHashFunc</p>
<p>默认值为 sha1，采用 sha1 加密算法生产 sessionid</p>
</li>
<li>
<p>web.BConfig.WebConfig.Session.SessionCookieLifeTime</p>
<p>设置 cookie 的过期时间，cookie 是用来存储保存在客户端的数据。</p>
</li>
</ul>
<p>&nbsp;</p>
<h1>2. 第三方依赖</h1>
<p>从beego 1.1.3 开始移除了第三方依赖库，如果想使用mysql等引擎，需要先安装依赖</p>
<pre class="language-bash"><code>go get -u github.com/beego/beego/v2/server/web/session/mysql</code></pre>
<p>&nbsp;</p>
<p>然后在main.go中引入依赖：</p>
<pre class="language-go"><code>import _  "github.com/beego/beego/v2/server/web/session/mysql"</code></pre>
<p>&nbsp;</p>
<p>（1）当SessionProvider为file时，SessionProviderConfig是保存文件的目录时，设置如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider= "file"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "./tmp"</code></pre>
<p>&nbsp;</p>
<p>（2）当SessionProvider为mysql时，SessionProviderConfig是mysql链接，格式为go-sql-driver，如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider =  "mysql"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "username:password@protocol(address)/dbname?param=value"</code></pre>
<p>&nbsp;</p>
<p>需要注意的是，在使用mysql存储session信息时，需要先在mysql中建表：</p>
<pre class="language-sql"><code>CREATE TABLE `session` (
    `session_key`  char (64)  NOT NULL ,
    `session_data` blob,
    `session_expiry`  int (11) unsigned  NOT NULL ,
    PRIMARY KEY (`session_key`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;</code></pre>
<p>&nbsp;</p>
<p>（3）当 SessionProvider 为 redis 时，SessionProviderConfig 是 redis 的链接地址，采用了&nbsp;<a href="https://github.com/garyburd/redigo">redigo</a>，如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider =  "redis"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "127.0.0.1:6379"</code></pre>
<p>&nbsp;</p>
<p>（4）当 SessionProvider 为 memcache 时，SessionProviderConfig 是 memcache 的链接地址，采用了&nbsp;<a href="https://github.com/beego/memcache">memcache</a>，如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider =  "memcache"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "127.0.0.1:7080"</code></pre>
<p>&nbsp;</p>
<p>（5）当 SessionProvider 为 postgres 时，SessionProviderConfig 是 postgres 的链接地址，采用了&nbsp;<a href="https://github.com/lib/pq">postgres</a>，如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider =  "postgresql"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "postgres://pqgotest:password@localhost/pqgotest?sslmode=verify-full"</code></pre>
<p>&nbsp;</p>
<p>（6）当 SessionProvider 为 couchbase 时，SessionProviderConfig 是 couchbase 的链接地址，采用了&nbsp;<a href="https://github.com/couchbaselabs/go-couchbase">couchbase</a>，如下所示：</p>
<pre class="language-go"><code>web.BConfig.WebConfig.Session.SessionProvider =  "couchbase"
web.BConfig.WebConfig.Session.SessionProviderConfig =  "http://bucketname:bucketpass@myserver:8091"</code></pre>
<p>&nbsp;</p>
<h2>注意：</h2>
<p>因为session内部采用了gob来注册存储的对象，例如struct，所以如果采用了非memory的引擎，请自己在main.go的init里面注册需要保存的这些结构体，不然会引起重启之后出现无法解析的错误</p>
<p>&nbsp;</p>