<h1>1. 切片的结构</h1>
<p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://img2022.cnblogs.com/blog/2794988/202203/2794988-20220326211723824-446981699.png" alt="" width="691" height="288" loading="lazy" /></p>
<p>&nbsp;</p>
<p>一个切片在运行时由指针、长度和容量三部分构成</p>
<p>指针指向切片元素对应的底层数组元素的地址；长度对应切片中元素的数目，长度不能超过容量；容量一般是从切片的开始位置到底层数组的结尾位置的长度</p>
<p>&nbsp;</p>
<h1>2. 切片的底层原理</h1>
<p>在编译时构建抽象语法树阶段会将切片构建为如下类型：</p>
<pre class="language-go"><code>type Slice  struct {
  Elem *Type
}</code></pre>
<p>&nbsp;</p>
<p>编译时使用NewSlice函数创建一个新的切片类型，并需要传递切片元素的类型。从中可以看出，切片元素的类型是在编译期间确定的</p>
<p>&nbsp;</p>
<h2>2.1 切片的make初始化</h2>
<p>在编译时，对于字面量的重要优化是判断变量应该被分配在栈区还是应该逃逸到堆区</p>
<p>如果make函数初始化了一个太大的切片，该切片就会逃逸到堆区；如果分配了一个比较小的切片，就会被分配到栈区</p>
<p>这个切片大小的临界值默认为64KB（不确定后续是否会存在优化），因此make([]int64, 1023) 和 make([]int64, 1024) 是完全不同的内存布局</p>
<p>&nbsp;</p>
<h2>2.2 切片扩容原理</h2>
<p>切片使用append函数添加元素，但不是使用了append就需要扩容</p>
<p>只要没有超过当前分配的cap大小，就不会发生扩容</p>
<p>切片扩容的现象说明了go语言并不会在每次append时都进行扩容，也不会每增加一个元素就扩容一次，因为扩容涉及内存分配，将损害性能</p>
<p>append函数的核心在运行时调用了runtime/slice.go文件下的growslice函数：</p>
<pre class="language-go"><code>func growslice(et *_type, old slice, cap int) slice {
    newcap := old.cap
    doublecap := newcap + newcap

    if cap &gt; doublecap {
        newcap = cap
    }  else {
        if old.len &lt; 1024 {
            newcap = doublecap
        }  else {
            for 0 &lt; newcap &amp;&amp; newcap &lt; cap {
                newcap += newcap / 4
            }
            if newcap &lt;= 0 {
                newcap = cap
            }
        }
    }
    ...
}</code></pre>
<p>&nbsp;</p>
<p>上面的代码显示了扩容的核心逻辑，golang中切片的扩容策略为：</p>
<ul>
<li>如果申请的容量cap大于2倍旧容量old.cap，最终新的容量newcap为新申请的容量</li>
<li>如果旧的切片长度小于1024，则最终容量是旧容量的2倍</li>
<li>如果旧切片长度大于或等于1024，则最终容量从旧容量开始循环增加1/4，直到最终容量大于或等于新申请的容量为止</li>
<li>如果最终容量计算值溢出，即超过了int的最大范围，则最终容量就是新申请的容量</li>
</ul>
<p>为了内存对齐，申请的内存可能大于实际类型✖️容量大小</p>
<p>&nbsp;</p>
<p>如果切片需要扩容，那么最后需要在堆区申请内存</p>
<p>扩容后的新切片不一定拥有新的地址，因此在使用append函数时，通常会采用 a = append(a, T) 的方式</p>
<p>当切片类型不是指针，分配内存后只需要将内存后面的值清空</p>
<p>当切片类型为指针，设计垃圾回收写屏障开启时，对旧切片中的指针指向的对象进行标记</p>
<p>&nbsp;</p>
<h2>2.3 切片复制</h2>
<p>复制的切片不会改变指向底层数组的数据源，但有些时候我们希望创建一个新的数组，并且与旧数组不共享相同的数据源，这时可以使用copy函数：</p>
<pre class="language-go"><code>// 创建目标切片
numbers1 := make([]int, len(numbers), cap(numbers)*2)

// 将numbers元素复制到numbers1中
count := copy(numbers1, numbers)</code></pre>
<p>&nbsp;</p>
<p>当然切片元素也可以直接复制给一个数组，但是要考虑二者容量的问题</p>
<p>如果在复制时，数组长度和切片的长度不相等，那么复制的元素为len(arr)和len(slice)的较小值</p>
<p>&nbsp;</p>
<p>copy函数在运行时主要调用了memmove函数，用于实现内存的复制</p>
<p>如果采用协程调用的方式go copy(arr,slice)或者加入了race检测，则会转而调用运行时slicestringcopy或者slicecopy函数，进行额外的检查</p>