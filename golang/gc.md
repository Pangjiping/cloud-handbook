<p><span style="font-size: 14pt;"><strong>1. golang垃圾回收</strong></span></p>
<p>golang的垃圾回收算法是三色标记法，其中三个颜色分别为：灰色、黑色、白色，其对应了垃圾回收过程中变量的三种状态：</p>
<ul>
<li>灰色：对象还在标记队列中等待</li>
<li>黑色：对象已经被标记，该对象不会在本次GC中被回收</li>
<li>白色：对象为被标记，该对象会在本地GC中被回收</li>
</ul>
<p>&nbsp;</p>
<p><strong>1.1 垃圾回收流程</strong></p>
<p>假设现在有这么几个对象：</p>
<p>&nbsp;</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321132510117-1966019488.png" alt="" width="550" height="193" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>有A-F六个对象，根对象a b为栈区分配的局部变量，根对象a b分别引用了对象 A B，而对象B有引用了对象D</p>
<p>下面简单看一下这几个对象的回收流程：</p>
<p>(1) 初始化：初始化时所有的对象都是白色</p>
<p>(2) 扫描：开始扫描根对象a b，由于a b引用了A B，所以A B设置为灰色</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321132956337-1897420331.png" alt="" width="567" height="179" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>(3) 分析：分析对象A，A没有引用其他对象，将A设置为黑色，B引用了D对象，则将B设置为黑色的同时，将D设置为灰色</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321133229033-544140605.png" alt="" width="573" height="169" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>(4)结束：重复步骤3，直到灰色队列为空，这时黑色队列中的对象会被保留，白色队列会被回收</p>
<p><img src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220321133351231-1649971669.png" alt="" width="572" height="183" loading="lazy" style="display: block; margin-left: auto; margin-right: auto;" /></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong>1.2 GC原理</strong></p>
<p>GC的原理简单来讲就是标记内存中哪些还在使用，哪些不被使用，而不被使用的部分就是GC的对象。</p>
<p>root区域主要是指程序运行到当前时刻的栈和全局数据区域，是正在使用到的内存，当然应该优先标记，而考虑到内存块中可能存放的事指针，所以开需要扫描灰色队列进行递归标记，待灰色队列为空，就可以将白色标记回收</p>
<p>&nbsp;</p>
<p><strong>1.3 GC优化</strong></p>
<p>golang的垃圾回收算法属于标记-清除，是需要STW的，在golang中就是要停掉所有goroutine，进行垃圾回收，待垃圾回收结束后再恢复goroutine。</p>
<p>所以，STW时间的长短直接影响了应用的执行，为了缩短STW时长，golang优化的GC算法，其中写屏障和辅助GC就是两种优化垃圾回收的方法</p>
<p>写屏障：</p>
<p>　　STW的目的是为了防止GC在扫描时出现内存变化而产生混乱，写屏障就是让goutine和GC同时运行，虽然不能完全消除STW，但可以大幅端减少STW时长。</p>
<p>　　写屏障在GC的特定时间开启，开启后指针传递时会把指针标记，即本轮不回收，下次GC时再确定。</p>
<p>辅助GC：</p>
<p>　　为了防止内存分配过快，在GC执行过程中，GC过程中mutator线程会并发运行，而mutator assisit机制会协助GC做一部分的工作。</p>
<p>&nbsp;</p>
<p><strong>1.4 GC触发机制</strong></p>
<ul>
<li>内存分配量达到阈值</li>
<li>定时触发</li>
<li>手动触发：runtime.GC()</li>
</ul>
<p>&nbsp;</p>
<p><strong>1.5 GC调优</strong></p>
<ul>
<li>控制内存分配的速度，限制 Goroutine 的数量，从而提高赋值器对 CPU 的利用率</li>
<li>减少并复用内存，例如使用 sync.Pool 来复用需要频繁创建临时对象，例如提前分配足够的内存来降低多余的拷贝</li>
<li>需要时，增大 GOGC 的值，降低 GC 的运行频率</li>
</ul>
<p>&nbsp;</p>
<p><span style="font-size: 14pt;"><strong>2. 内存逃逸分析</strong></span></p>
<p>golang中堆栈对于程序员是透明的，栈空间回收更快，堆空间需要触发GC。</p>
<p>逃逸分析，可以尽量把那些不需要分配到堆上的变量直接分配到栈上。</p>
<p>&nbsp;</p>
<p><strong>2.1 逃逸分析</strong></p>
<p>逃逸分析一个最基本的原则就是：如果一个函数返回对一个变量的引用，那么它就会发生逃逸</p>
<p>逃逸的常见情况：</p>
<ul>
<li>发送指针的指针或值包含了指针到 channel 中，由于在编译阶段无法确定其作用域与传递的路径，所以一般都会逃逸到堆上分配</li>
<li>slices 中的值是指针的指针或包含指针字段</li>
<li>slice 由于 append 操作超出其容量，因此会导致 slice 重新分配</li>
<li>调用接口类型的方法</li>
<li>尽管能够符合分配到栈的场景，但是其大小不能够在在编译时候确定的情况，也会分配到堆上</li>
</ul>
<p>&nbsp;</p>
<p><strong>2.2 如何避免内存逃逸</strong></p>
<ul>
<li>减少外部引用, 如指针</li>
<li>应该尽量避免使用接口类型</li>
<li>声明切片的时候，使用make指明初始大小，尽量避免append</li>
</ul>
<p>&nbsp;</p>