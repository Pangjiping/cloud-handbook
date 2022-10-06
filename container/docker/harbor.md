<h2>1. 什么是Harbor</h2>
<p>Harbor是由VMWare公司开源的容器镜像仓库</p>
<p>事实上，Harbor就是在Docker Registry上进行了相应的企业级扩展，从而获得了更加广泛的应用</p>
<p>我们都知道Docker Registry是命令行操作的，对于运维非常不友好，所以Harbor所做的扩展基本就包括了以下几个方面：</p>
<ul>
<li>管理用户界面</li>
<li>基于角色的访问控制</li>
<li>AD/LDAP集成以及审计日志</li>
</ul>
<p>&nbsp;</p>
<p>Harbor的相关组件如下：</p>
<table style="height: 350px; width: 766px;" border="0" align="center">
<tbody>
<tr>
<td align="left">组件</td>
<td align="left">功能</td>
</tr>
<tr>
<td align="left">harbor-adminserver</td>
<td align="left">配置管理中心</td>
</tr>
<tr>
<td align="left">harbor-db</td>
<td align="left">mysql数据库</td>
</tr>
<tr>
<td align="left">harbor-jobservice</td>
<td align="left">镜像复制</td>
</tr>
<tr>
<td align="left">harbor-log</td>
<td align="left">记录操作日志</td>
</tr>
<tr>
<td align="left">harbor-ui</td>
<td align="left">web页面和api</td>
</tr>
<tr>
<td align="left">nginx</td>
<td align="left">前端代理，负责前端页面和镜像上传、下载</td>
</tr>
<tr>
<td align="left">redis</td>
<td align="left">会话</td>
</tr>
<tr>
<td align="left">registry</td>
<td align="left">镜像存储</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<h2>2. 搭建一个harbor仓库</h2>
<p>在搭建一个仓库之前，首先需要docker和docker-compose环境</p>
<p>docker-compose就是一个单机的容器编排工具，可以快速将多个容器部署到一个网络内，并且可以确定容器创建的顺序</p>
<p>docker之前已经安装过了，这里只写一下安装docker-compose，docker-compose就是一个二进制文件</p>
<pre class="language-bash"><code>curl -L https://get.daocloud.io/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose &gt; /dev/null</code></pre>
<div class="cnblogs_code">&nbsp;</div>
<pre class="language-bash"><code>sudo chmod +x /usr/local/bin/docker-compose</code></pre>
<p>&nbsp;</p>
<p>下载harbor安装包</p>
<p><a href="https://github.com/goharbor/harbor/releases">Releases &middot; goharbor/harbor (github.com)</a></p>
<p>下载完成之后解压包</p>
<pre class="language-bash"><code>tar zxvf harbor-offline-installer-v2.4.2.tgz</code></pre>
<p>&nbsp;</p>
<p>解压之后进入到harbor目录可以看到一些文件</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405105412311-1736101020.png" alt="" width="664" height="125" loading="lazy" /></p>
<p>&nbsp;</p>
<p>首先需要执行prepare脚本，会拉取一些镜像到本地</p>
<pre class="language-bash"><code>./prepare</code></pre>
<p>&nbsp;</p>
<p>注意prepare脚本需要harbor.yml文件，上面那个harbor.yml.tmpl需要重命名或者复制一份为.yml格式</p>
<p>再安装之前需要修改一下ymal文件，主要是修改hostname为自己的ip地址即可</p>
<p>如果不需要https，记得把https的配置注释掉</p>
<pre class="language-bash"><code># The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: &lt;your ip&gt;

# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 80

# https related config
#https:
  # https port for harbor, default is 443
  # port: 443
  # The path of cert and key files for nginx
  #certificate: /your/certificate/path
  #private_key: /your/private/key/path

# # Uncomment following will enable tls communication between all harbor components
# internal_tls:
#   # set enabled to true means internal tls is enabled
#   enabled: true</code></pre>
<p>&nbsp;</p>
<p>修改完之后就可以安装了</p>
<pre class="language-bash"><code>./install.sh</code></pre>
<p>&nbsp;</p>
<p>有个地方可能会发生错误，当然提示信息也很明显，我们已经有一个名叫redis的容器了，和harbor的redis容器冲突，所以我们需要重命名一下自己的那个redis</p>
<pre class="language-bash"><code>ERROR: for redis  Cannot create container for service redis: Conflict. The container name "/redis" is already in use by container "7fdfbb3450db2cf83b0290c6989fedb3f049f4deca99eb4328816fb603a4db5d". You have to remove (or rename) that container to be able to reuse that name.</code></pre>
<p>&nbsp;</p>
<p>安装完成之后可以查看一下各个组件的状态</p>
<pre class="language-bash"><code>docker-compose ps</code></pre>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405131956288-1848006595.png" alt="" width="698" height="160" loading="lazy" /></p>
<p>&nbsp;</p>
<p>最后可以访问我们设置的hostname来访问harbor</p>
<p>默认的用户名和密码在harbor.yml文件中可以找到</p>
<p>默认用户：admin，密码：Harbor12345</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220405132349292-1875676260.png" alt="" width="842" height="414" loading="lazy" /></p>
<p>&nbsp;</p>
<p>如果要向harbor推送镜像，而没有启用https的话，可能会报错拒绝访问，这时候我们需要添加一个可信任仓库地址</p>
<p>制作镜像的时候需要打标签，具体可见每个仓库的推送命令，会有提示</p>
<p>记得要先登录在push</p>
<p>&nbsp;</p>
<p>参考：</p>
<p><a href="https://blog.csdn.net/song_java/article/details/88061162">ubuntu安装docker和docker-compose_五克松的博客-CSDN博客</a></p>
<p><a href="https://www.cnblogs.com/wxwgk/p/13287336.html">harbor搭建及使用 - 浪淘沙&amp; - 博客园 (cnblogs.com)</a></p>
<p>&nbsp;</p>