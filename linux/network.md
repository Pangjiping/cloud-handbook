<p><span style="font-size: 14pt;"><strong>1. hostname</strong></span></p>
<ul>
<li>
<p>hostname 没有选项，显示主机名字</p>
</li>
<li>
<p>hostname &ndash;d 显示机器所属域名</p>
</li>
<li>
<p>iwhostname &ndash;f 显示完整的主机名和域名</p>
</li>
<li>hostname &ndash;i 显示当前机器的ip地址</li>
</ul>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>2. ping</strong></span></p>
<p>ping 将数据包发向用户指定地址。当包被接收，目标机器发送返回数据包。ping 主要有两个作用：</p>
<ul>
<li>检查网络是否通畅</li>
<li>检查连接的速度</li>
</ul>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>3. ifconfig</strong></span></p>
<p>查看用户网络配置。它显示当前网络设备配置</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>4. iwconfig</strong></span></p>
<p>iwconfig 工具与 ifconfig 和ethtool类似，是用于无线网卡的。</p>
<p>可以用他查看设置基本的Wi-Fi 网络信息：例如 SSID、channel和encryption</p>
<p>还有其他很多配置你也可以查看和修改，包括：接收灵敏度,、RTS/CTS,、发送数据包的分片大小、以及无线网卡的重传机制</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>5. nslookup</strong></span></p>
<p>nslookup 这个命令在有ip地址时，可以用这个命令来显示主机名，可以找到给定域名的所有ip地址</p>
<p>nsloopup blogger.com</p>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321194524892-1865558879.png" alt="" width="554" height="363" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p><span style="font-size: 14pt;"><strong>6. traceroute</strong></span></p>
<p>可用来查看数据包在提交到远程系统或者网站时候所经过的路由器的IP地址、跳数和响应时间</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321195246173-203759490.png" alt="" width="613" height="367" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p><span style="font-size: 14pt;"><strong>7. finger</strong></span></p>
<p>查看用户信息</p>
<p>显示用户的登录名字、真实名字以及登录终端的名字和登录权限</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>8. telnet</strong></span></p>
<p>通过telnet协议连接目标主机，如果telnet连接可以在任一端口上完成即代表着两台主机间的连接良好</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>9. ethtool</strong></span></p>
<p>ethtool允许你查看和更改网卡的许多设置（不包括Wi-Fi网卡）。你可以管理许多高级设置，包括tx/rx、校验及网络唤醒功能。下面是一些你可能感兴趣的基本命令：</p>
<p>ethtool -i 显示一个特定网卡的驱动信息，检查软件兼容性时尤其有用</p>
<p>ethtool -p 启动一个适配器的指定行为，比如让适配器的LED灯闪烁，以帮助你在多个适配器或接口中标识接口名称</p>
<p>ethtool -s 显示网络统计信息</p>
<p>ethtool speed &lt;10|100|1000&gt; 设置适配器的连接速度，单位是Mbps</p>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>10. netstat</strong></span></p>
<p>发现主机连接最有用最通用的Linux命令。你可以使用&rdquo;netstat -g&rdquo;查询该主机订阅的所有多播组（网络）</p>
<p>netstat -nap |&nbsp;<span class="wp_keywordlink">grep&nbsp;port 将会显示使用该端口的应用程序的进程id</span></p>
<p>netstat -a or netstat &ndash;all 将会显示包括TCP和UDP的所有连接</p>
<p>netstat &ndash;tcp or netstat &ndash;t 将会显示TCP连接</p>
<p>netstat &ndash;udp or netstat &ndash;u 将会显示UDP连接</p>
<p>netstat -g 将会显示该主机订阅的所有多播网络。</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321195208634-1599366594.png" alt="" width="579" height="347" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>参考：</p>
<p>https://www.linuxprobe.com/ten-linux-control.html</p>
<p>&nbsp;</p>