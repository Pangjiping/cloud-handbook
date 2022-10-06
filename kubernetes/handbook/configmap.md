<h1>1. Secret</h1>
<p>加密数据并存放在etcd中，让pod内容器以挂载volume方式访问</p>
<p>应用场景：凭据、用户名密码、https证书、docker仓库认证</p>
<p>&nbsp;</p>
<p>pod使用secret的两种方式：</p>
<ul>
<li>变量注入</li>
<li>挂载</li>
</ul>
<p>&nbsp;</p>
<h2>1.1 secret使用</h2>
<p>首先创建一个secret来保存一个常规的用户名和密码</p>
<p>如果我们要存放一个用户名和密码的话，也不建议直接在YAML文件中体现，一般而言会做一个简单的编码，这样在查看资源配置的时候不至于直接输密码</p>
<pre class="language-bash"><code>echo -n 'admin' | base64
echo -n '1f2d1e2e67df' | base64</code></pre>
<p>&nbsp;</p>
<p>然后编写一个最简单的Secret资源，可以把data字段中的值理解为key-value形式</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220408153950433-1721728568.png" alt="" width="766" height="617" loading="lazy" /></p>
<p>&nbsp;</p>
<p>创建资源</p>
<pre class="language-bash"><code>kubectl apply -f secret_var.yaml</code></pre>
<p>&nbsp;</p>
<p>如果想要以变量注入的形式来让pod使用这个用户名和密码，我们需要在创建pod的YAML文件中选择使用env字段</p>
<p>valueFrom指明这个变量值来自于哪个资源，secretKeyRef表示这个值来自于名为mysecret的secret资源，key为username</p>
<p>这样就完成了username和password的变量注入，而在容器中就可以使用SECRET_USERNAME和SECRET_PASSWORD</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220408154429201-1246930686.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>以挂载的方式使用secret，需要在创建pod的YAML文件中声明要使用的secret资源</p>
<p>这样一来secret所保存的用户名和密码都会被挂载到pod内的/etc/foo目录下，容器只需要读取这个目录下的文件就可以完成配置</p>
<p>文件名就是key的名字，即username</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220408154902043-1889607643.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<h1>2. Configmap</h1>
<p>Configmap和Secret的使用几乎是一样的，不过其应用场景是多用于配置信息的分发</p>
<p>&nbsp;</p>
<h1>3. 应用程序如何动态更新配置</h1>
<p>configmap和secret修改了，如何在pod中实现更新？</p>
<ul>
<li>重建pod</li>
<li>应用程序实现watch etcd中的配置文件，发现变化更新配置信息</li>
<li>使用sidecar的逻辑监听配置更新，启用一个辅助容器来监听</li>
</ul>
<p>如果脱离k8s，可以采用配置中心的方式</p>
<p>&nbsp;</p>