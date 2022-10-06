# **golang读取文件总结**

## **1. 读取整个文件**

读取整个文件是效率最高的一种方式，但其只适用于小文件，大文件一次读取会消耗大量内存

<br>

### **1.1 使用文件名直接读取**

使用`os.ReadFile()`方法可以实现直接读取

```golang
func fileOne() {
	content, err := os.ReadFile("test.txt")
	if err != nil {
		panic(err)
	}
	fmt.Println(string(content))
}
```

使用`ioutil.ReadFile()`方法可以实现一样的效果，这两个函数其实是完全一样的

```golang
func fileTwo() {
	content, err := ioutil.ReadFile("test.txt")
	if err != nil {
		panic(err)
	}
	fmt.Println(string(content))
}
```

<br>

### **1.2 先创建文件句柄再读取文件**

如果想以只读方式打开文件的话，可以直接使用`os.Open()`方法

```golang
func fileThree() {
	file, err := os.Open("test.txt")
	if err != nil {
		panic(err)
	}
	defer file.Close()
 
	content, err := ioutil.ReadAll(file)
	fmt.Println(string(content))
}
```

或者使用通用的`os.OpenFile()`方法，不过要多加两个参数

```golang
func fileFour() {
	file, err := os.OpenFile("test.txt", os.O_RDONLY, 0)
	if err != nil {
		panic(err)
	}
	defer file.Close()
 
	content, err := ioutil.ReadAll(file)
	fmt.Println(string(content))
}
```

<br>

## **2. 按行读取**

按行读取主要使用`ioutil`库，其中有两个方法可以实现按行读取

但要注意的是，按行读取是以`'\n'`来区分每一行的，如果是没有分行的大文件，就不能使用按行读取了

使用`ioutil.ReadBytes()`实现按行读取文件

```golang
func fileFive() {
	// 创建文件句柄
	fi, err := os.Open("test.txt")
	if err != nil {
		panic(err)
	}
	defer fi.Close()
 
	// 创建reader
	r := bufio.NewReader(fi)
 
	for {
		lineBytes, err := r.ReadBytes('\n')
		line := strings.TrimSpace(string(lineBytes))
		if err != nil && err != io.EOF {
			panic(err)
		}
		if err == io.EOF {
			break
		}
		fmt.Println(line)
	}
}
```

使用`ioutil.ReadString()`同样可以实现按行读取

```golang
func fileSix() {
	// 创建文件句柄
	fi, err := os.Open("test.txt")
	if err != nil {
		panic(err)
	}
	defer fi.Close()
 
	// 创建reader
	r := bufio.NewReader(fi)
 
	for {
		line, err := r.ReadString('\n')
		line = strings.TrimSpace(line)
		if err != nil && err != io.EOF {
			panic(err)
		}
		if err == io.EOF {
			break
		}
		fmt.Println(line)
	}
}
```

<br>

## **3. 按字节数读取**

对于不分行的大文件来说，只能使用按字节读取来读取整个文件

按字节读取可以使用`os`库或者`syscall`库来实现

使用`os`库实现按字节读取

```golang
func fileSeven() {
	// 创建文件句柄
	fi, err := os.Open("test.txt")
	if err != nil {
		panic(err)
	}
	defer fi.Close()
 
	// 创建reader
	r := bufio.NewReader(fi)
 
	// 每次读取1024个字节
	buf := make([]byte, 1024)
	for {
		n, err := r.Read(buf)
		if err != nil && err != io.EOF {
			panic(err)
		}
		if n == 0 {
			break
		}
		fmt.Println(string(buf[:n]))
	}
}
```

使用`syscall`库实现按字节读取

```golang
func fileEight() {
	fd, err := syscall.Open("test.txt", syscall.O_RDONLY, 0)
	if err != nil {
		fmt.Println("Failed on open: ", err)
	}
	defer syscall.Close(fd)
 
	var wg sync.WaitGroup
	wg.Add(2)
	dataChan := make(chan []byte)
	go func() {
		wg.Done()
		for {
			data := make([]byte, 100)
			n, _ := syscall.Read(fd, data)
			if n == 0 {
				break
			}
			dataChan <- data
		}
		close(dataChan)
	}()
 
	go func() {
		defer wg.Done()
		for {
			select {
			case data, ok := <-dataChan:
				if !ok {
					return
				}
 
				fmt.Println(string(data))
			default:
			}
		}
	}()
 
	wg.Wait()
}
```

<br>