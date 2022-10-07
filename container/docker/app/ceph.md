<p>1. 创建ceph专用网络</p>
<pre class="language-bash"><code>docker network create --driver bridge --subnet 172.20.0.0/16 ceph-network</code></pre>
<p>&nbsp;</p>
<p>之后我们使用docker网络相关指令可以看到创建的 ceph-network 相关信息</p>
<pre class="language-bash"><code>docker network inspect ceph-network</code></pre>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220403093435222-871390415.png" alt="" width="795" height="466" loading="lazy" /></p>
<p>&nbsp;</p>
<p>2. 拉取ceph镜像</p>
<pre class="language-bash"><code>docker pull ceph/daemon:latest-luminous</code></pre>
<p>&nbsp;</p>
<p>如果没有修改为国内的镜像源，先去修改镜像源再pull，这个镜像挺大的</p>
<p>之后查看镜像信息</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220403093634356-540782132.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>3. 搭建monitor节点</p>
<pre class="language-bash"><code>docker run -d --name ceph-mon --network ceph-network --ip 172.20.0.10 -e CLUSTER=ceph -e WEIGHT=1.0 -e MON_IP=172.20.0.10 -e MON_NAME=ceph-mon -e CEPH_PUBLIC_NETWORK=172.20.0.0/16 -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /var/log/ceph/:/var/log/ceph/ ceph/daemon:latest-luminous mon</code></pre>
<p>&nbsp;</p>
<p>4. 搭建osd节点</p>
<pre class="language-bash"><code>docker exec ceph-mon ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring</code></pre>
<p>&nbsp;</p>
<p>修改配置文件以兼容etx4硬盘</p>
<pre class="language-bash"><code>vi /etc/ceph/ceph.conf</code></pre>
<p>在文件最后追加：</p>
<pre class="language-bash"><code>osd max object name len = 256
osd max object namespace len = 64</code></pre>
<p>&nbsp;</p>
<p>分别启动三个容器来模拟集群</p>
<pre class="language-bash"><code>docker run -d --privileged=true --name ceph-osd-1 --network ceph-network --ip 172.20.0.11 -e CLUSTER=ceph -e WEIGHT=1.0 -e MON_NAME=ceph-mon -e MON_IP=172.20.0.10 -e OSD_TYPE=directory -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /var/lib/ceph/osd/1:/var/lib/ceph/osd -v /etc/localtime:/etc/localtime:ro ceph/daemon:latest-luminous osd</code></pre>
<pre class="language-bash"><code>docker run -d --privileged=true --name ceph-osd-2 --network ceph-network --ip 172.20.0.12 -e CLUSTER=ceph -e WEIGHT=1.0 -e MON_NAME=ceph-mon -e MON_IP=172.20.0.10 -e OSD_TYPE=directory -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /var/lib/ceph/osd/2:/var/lib/ceph/osd -v /etc/localtime:/etc/localtime:ro ceph/daemon:latest-luminous osd</code></pre>
<pre class="language-bash"><code>docker run -d --privileged=true --name ceph-osd-3 --network ceph-network --ip 172.20.0.13 -e CLUSTER=ceph -e WEIGHT=1.0 -e MON_NAME=ceph-mon -e MON_IP=172.20.0.10 -e OSD_TYPE=directory -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ -v /var/lib/ceph/osd/3:/var/lib/ceph/osd -v /etc/localtime:/etc/localtime:ro ceph/daemon:latest-luminous osd</code></pre>
<p>&nbsp;</p>
<p>5. 搭建mgr节点</p>
<pre class="language-bash"><code>docker run -d --privileged=true --name ceph-mgr --network ceph-network --ip 172.20.0.14 -e CLUSTER=ceph -p 7000:7000 --pid=container:ceph-mon -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph/ ceph/daemon:latest-luminous mgr</code></pre>
<p>&nbsp;</p>
<p>开启管理界面</p>
<pre class="language-bash"><code>docker exec ceph-mgr ceph mgr module enable dashboard</code></pre>
<p>&nbsp;</p>
<p>6. 搭建rgw节点</p>
<pre class="language-bash"><code>docker exec ceph-mon ceph auth get client.bootstrap-rgw -o /var/lib/ceph/bootstrap-rgw/ceph.keyring</code></pre>
<pre class="language-bash"><code>docker run -d --privileged=true --name ceph-rgw --network ceph-network --ip 172.20.0.15 -e CLUSTER=ceph -e RGW_NAME=ceph-rgw -p 7480:7480 -v /var/lib/ceph/:/var/lib/ceph/ -v /etc/ceph:/etc/ceph -v /etc/localtime:/etc/localtime:ro ceph/daemon:latest-luminous rgw</code></pre>
<p>&nbsp;</p>
<p>7. 检查ceph状态</p>
<pre class="language-bash"><code>docker exec ceph-mon ceph -s</code></pre>
<p>&nbsp;</p>
<p>8. 测试添加rgw用户，生成access_key和secret_key用于访问</p>
<pre class="language-bash"><code>docker exec ceph-rgw radosgw-admin user create --uid="test" --display-name="test user"</code></pre>
<p>&nbsp;</p>
<p>9. 使用docker ps 查看ceph运行状态</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202204/2794988-20220403112500638-483865337.png" alt="" loading="lazy" /></p>
<p>&nbsp;</p>
<p>10 查看ceph健康状态</p>
<pre class="language-bash"><code>docker exec ceph-mon ceph -s</code></pre>
<p>&nbsp;</p>
<p>11. 进入ceph-mon</p>
<pre class="language-bash"><code>docker exec -it ceph-mon bash</code></pre>
<p>&nbsp;</p>