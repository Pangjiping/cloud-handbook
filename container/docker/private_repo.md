<p>前段时间在部署一个项目时，需要将本机mac上的golang应用部署到服务器上，但是又不想直接传到公有仓库上，需要一个私人仓库地址便于管理这些项目镜像</p>
<p>下面记录一次私有仓库创建到镜像push和pull的过程。</p>
<p>&nbsp;</p>
<p>1.&nbsp;docker官方提供了一个工具docker-registry，我们可以借助这个工具构建私有镜像仓库，首先search registry</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319102220487-1121983826.png" alt="" width="649" height="315" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>2. 我们选择官方版本就可以，执行 docker pull registry等待镜像拉取完成</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319102637444-1999107928.png" alt="" width="629" height="236" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>3. 通过docker images命令我们可以看到镜像已经拉取成功，现在让我们运行镜像</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319103114457-1582739244.png" alt="" width="626" height="77" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>指定一个对外暴露端口，容器内默认是5000，但是可以看到我第一次暴露5000端口，系统监听到端口被占用了，所以我更改了另一个端口映射，记住映射的哪个端口就好了。如果记不住的话，可以查看docker ps看到所有容器的运行信息，其中包含端口映射信息，或者更简单一点使用mac客户端查看docker所有容器和镜像的状态</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319103600401-734402669.png" alt="" width="665" height="385" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>4. 创建好容器之后，我们就可以开始使用私有仓库了，首先查看本机ip地址，并制作一个小的镜像做实验</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319103951546-1559381015.png" alt="" width="643" height="190" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>为了测试我又拉取了一个redis的镜像</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319104231634-14365334.png" alt="" width="651" height="96" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>下面让我们修改这个镜像名称，打上我们私有仓库的专属标签</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319104837449-1798682005.png" alt="" width="640" height="129" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>5. 上传镜像文件</p>
<p>运行docker push可能会遇到下面的错误：</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319105734424-1866689646.png" alt="" width="653" height="110" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>进入docker客户端，修改docker daemon.json，加上我们的ip地址，然后重启docker服务，重启registry</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319105702551-360194288.png" alt="" width="723" height="359" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>再执行一遍docker push就可以成功上传镜像文件了</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319110114718-1866759805.png" alt="" width="728" height="178" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>6. 查看镜像</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220319112835547-1986658992.png" alt="" width="725" height="78" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>