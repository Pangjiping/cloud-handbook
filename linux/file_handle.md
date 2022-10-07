<h2>1. 查看当前系统的最大句柄数</h2>
<div class="cnblogs_code">
<pre>ulimit -n</pre>
</div>
<p>&nbsp;</p>
<h2>2. lsof</h2>
<p>lsof命令查看有关文件句柄的详细信息，如当前系统打开的文件数量，哪些进程在使用这些文件句柄等等</p>
<p>查看进程PID打开的文件句柄详细信息：</p>
<div class="cnblogs_code">
<pre>lsof -p &lt;pid&gt;</pre>
</div>
<p>&nbsp;</p>
<p>查看当前进程打开了多少句柄数：</p>
<div class="cnblogs_code">
<pre>lsof -n|<span style="color: #0000ff;">awk</span> <span style="color: #800000;">'</span><span style="color: #800000;">{print $2}</span><span style="color: #800000;">'</span>|<span style="color: #0000ff;">sort</span>|<span style="color: #0000ff;">uniq</span> -c|<span style="color: #0000ff;">sort</span> -nr|<span style="color: #0000ff;">more</span></pre>
</div>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>参考：</p>
<p>https://blog.csdn.net/qq_40910541/article/details/88965420</p>
<p>https://www.cnblogs.com/cloudwind2011/p/6409074.html</p>