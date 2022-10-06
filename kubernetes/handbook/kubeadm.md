<h1>1. 配置要求</h1>
<p>至少三台虚拟机，一个master两个node</p>
<p>硬件配置：2GBRAM，2个CPU，30GB磁盘</p>
<p>操作系统：centos 7.x</p>
<p>禁止swap分区</p>
<p>可以访问外网，网络互通</p>
<p>&nbsp;</p>
<table style="height: 131px; width: 470px;" border="0">
<tbody>
<tr>
<td>角色</td>
<td>IP</td>
</tr>
<tr>
<td>k8s-master</td>
<td>&nbsp;192.168.241.133</td>
</tr>
<tr>
<td>k8s-node1</td>
<td>&nbsp;192.168.241.132</td>
</tr>
<tr>
<td>k8s-node2</td>
<td>&nbsp;192.168.241.131</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p>&nbsp;</p>
<h1>2. 配置步骤</h1>
<p>########################在所有节点上执行#####################################</p>
<p>（1）关闭防火墙</p>
<pre class="language-bash"><code>systemctl stop firewalld
systemctl disable firewalld #永久</code></pre>
<p>&nbsp;</p>
<p>（2）关闭selinux</p>
<pre class="language-bash"><code>sed -i 's/enforcing/disabled/' /etc/selinux/config # 永久
setenforce 0 # 临时</code></pre>
<p>&nbsp;</p>
<p>（3）关闭swap</p>
<pre class="language-bash"><code>swapoff -a #临时
vim /etc/fstab # 永久，注释掉swap的开机启动</code></pre>
<p>&nbsp;</p>
<p>（4）设置主机名</p>
<pre class="language-bash"><code>hostnamectl set-hostname &lt;hostname&gt;</code></pre>
<p>&nbsp;</p>
<p>#####################################################################</p>
<p>&nbsp;</p>
<p>（5）在master节点中添加hosts</p>
<pre class="language-bash"><code>cat &gt;&gt; etc/hosts &lt;&lt; EOF
192.168.31.61 k8s-master
192.168.31.62 k8s-node1
192.168.31.63 k8s-node2
EOF</code></pre>
<p>&nbsp;</p>
<p>（6）修改master节点的网络配置</p>
<pre class="language-bash"><code>cat &gt; /etc/sysctl.d/k8s.conf &lt;&lt;EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF</code></pre>
<p>&nbsp;</p>
<p>（7）配置生效</p>
<pre class="language-bash"><code>sysctl --system</code></pre>
<p>&nbsp;</p>
<p>#################以下在所有节点上执行##########################</p>
<p>（8）同步时钟</p>
<pre class="language-bash"><code>ntpdate time.windows.com</code></pre>
<p>&nbsp;</p>
<p>（9）安装docker，并修改镜像源，然后重启docker服务就好了</p>
<pre class="language-bash"><code>wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo</code></pre>
<pre class="language-bash"><code>yum -y install docker-ce-18.06.1.ce-3.el7</code></pre>
<pre class="language-bash"><code>systemctl enable docker &amp;&amp; systemctl start docker</code></pre>
<pre class="language-bash"><code>cat &gt; /etc/docker/daemon.json &lt;&lt; EOF
{"registry-mirrors":["https://dr0fajwf.mirror.aliyuncs.com"]}
EOF</code></pre>
<pre class="language-bash"><code>systemctl restart docker</code></pre>
<div class="cnblogs_code">
<pre>&nbsp;</pre>
</div>
<p>&nbsp;</p>
<p>（10）修改yum源</p>
<pre class="language-bash"><code>cat  &gt; /etc/yum.repos.d/kubernetes.repo &lt;&lt;EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF</code></pre>
<p>&nbsp;</p>
<p>（11）安装kubelet kubeadm kubectl</p>
<pre class="language-bash"><code>yum install -y kubelet kubeadm kubectl</code></pre>
<p>&nbsp;</p>
<p>默认最新版，可以指定版本</p>
<p>##################################################################</p>
<p>&nbsp;</p>
<p>（12）初始化k8s集群</p>
<pre class="language-bash"><code>kubeadm init &gt;   --apiserver-advertise-address=192.168.241.133 &gt;   --image-repository registry.aliyuncs.com/google_containers &gt;   --kubernetes-version v1.23.5 &gt;   --service-cidr=10.96.0.0/12 &gt;   --pod-network-cidr=10.244.0.0/16</code></pre>
<p>&nbsp;</p>
<p>（13）成功后看到提示信息，需要拷贝三个东西，还有提示如何让node加入集群中</p>
<p>&nbsp;</p>
<p>（14）查看node状态，可能是NotReady，需要下载一个yml文件</p>
<pre class="language-bash"><code>kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml</code></pre>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406134423169-2088650693.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>（15）如果有需要的话可以安装bashboard</p>
<pre class="language-bash"><code>wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml</code></pre>
<p>&nbsp;</p>
<p>下载完成后打开，修改Service，暴露端口</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406134738454-395588795.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>然后应用这个yaml文件就可以</p>
<pre class="language-bash"><code>kubectl apply -f recommended.yaml</code></pre>
<p>&nbsp;</p>
<p>（16）访问bashboard</p>
<p>访问方式见&nbsp;<a href="https://kuboard.cn/install/install-k8s-dashboard.html">安装Kubernetes Dashboard | Kuboard</a></p>
<p>&nbsp;</p>
<p>（17）测试</p>
<p>最后通过以下几个指令查看一下集群的状态：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406150545016-1088943209.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>尝试部署一个nginx</p>
<pre class="language-bash"><code>kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort</code></pre>
<p>&nbsp;</p>
<p>查看nginx的信息，使用浏览器访问</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220406150851111-1162861768.png" alt="" width="944" height="458" loading="lazy" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>kubectl进入pod的指令和docker进入容器的指令差不多，bash前面不用加 -- 也可以，不过会提示说将来版本会弃用完全像docker的这种写法</p>
<p>&nbsp;</p>
<h1>3. k8s集群初始化流程</h1>
<ol>
<li>检查系统环境是否满足，例如swap是否关闭、配置是否满足等</li>
<li>下载所需镜像，kubeadm config images pull</li>
<li>为kubelet创建配置文件并启动</li>
<li>为apiserver、etcd生成https证书</li>
<li>生成连接apiserver的kubeconfig文件</li>
<li>容器启动master组件</li>
<li>将涉及的配置文件存储到configmap</li>
<li>设置master节点不可调度pod</li>
<li>启用bootstrap自动为kubelet颁发证书</li>
<li>安装插件coreDNS、kube-proxy</li>
</ol>
<p>&nbsp;</p>