<p>golang中的defer可以给我们编程带来很大的遍历，一些操作可以使用defer来防止不及时的关闭等</p>
<p>比如互斥锁、文件句柄、数据库连接等</p>
<p>比如一个文件操作：</p>
<pre class="language-go"><code>func main() {
    file, err := os.Open( "test.txt" )
    if err != nil {
        log.Println(err)
        return
    }
    defer file.Close()
   
    // ...
}</code></pre>
<p>　　</p>
<p>用GoLand等IDE的同学会经常注意到IDE给我们提示的一个信息：Unhandled error&nbsp;</p>
<p>也就是说，file.Close()是有可能返回err的，但是我们并没有处理</p>
<p>虽然我们把file.Close()放到了函数最后执行，也不在乎它是不是返回错误，但是重要的不是错误本身，而是file没有按照我们的想法而关闭</p>
<p>但是由于其被写在了defer中，所以无法对错误进行处理</p>
<p>&nbsp;</p>
<p>那么，对于文件操作，什么情况下才会file.Close()报错呢？</p>
<p>在defer file.Close()执行时，操作系统还未将数据刷到磁盘，这时我们应该收到错误提示，但是我们却忽略了这个错误</p>
<p>&nbsp;</p>
<p>那么在特殊情况下的defer应该怎么写？</p>
<p>建议通过命名返回值和闭包来处理：</p>
<pre class="language-go"><code>func fileClose() (err error) {
    file, err := os.Open( "test.txt" )
    if err != nil {
        return err
    }
    defer func () {
        closeErr := file.Close()
        if err == nil {
            err = closeErr
        }
    }()

    _, err = io.WriteString(file,  "hello golang" )
    return
}</code></pre>
<p>&nbsp;</p>