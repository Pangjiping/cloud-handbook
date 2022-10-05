# **golang flag库的基本用法**

## **1. flag库的基本用法**

下面是一个golang flag库的命令行demo程序

```golang
func main() {
	wordPtr := flag.String("word", "Jude", "a string")
	numPtr := flag.Int("numb", 42, "an int")
	boolPtr := flag.Bool("fork", false, "a bool")
 
	var svar string
	flag.StringVar(&svar, "svar", "bar", "a string var")
 
	flag.Parse()
 
	fmt.Println("word: ", *wordPtr)
	fmt.Println("numb: ", *numPtr)
	fmt.Println("fork: ", *boolPtr)
	fmt.Println("svar: ", svar)
	fmt.Println("tail: ", flag.Args())
}
```

使用flag包可以为程序声明字符串类型、数字类型、布尔类型的命令行flag

* `flag.String("word","Jude","a string")`声明了一个字符串类型的flag `word`，制定了它的默认值和简介。flag.String函数返回一个字符串类型的指针（不是字符串值）
* 声明`numb`和`fork`这两个flag的函数`flag.Int()`和`flag.Bool()`，使用方法和`flag.String()`一样
* `flag.StringVar(&svar,"svar","bar","a string var")`这个形式的函数可以把命令行flag参数值解析到程序中的已存在变量，需要注意的是函数接受的是以存在变量的指针
* 定义完所有的命令行flag之后，调用`flag.Parse()`函数去执行命令行解析
* 上面的程序只是打印出了所有命令行flag的值以及位置参数的值。注意我们需要对`wordPtr`这几个存储了指针的变量进行解引用`*wordPtr`才能拿到具体的命令行flag值

在终端运行这个demo，后面加上命令行参数就行

```bash
$ go run main.go -word=opt -numb=7 -fork -svar=flag
 
word:  opt
numb:  7
fork:  true
svar:  flag
tail:  []
```

执行命令时被忽略的flag会被设置为默认值

```bash
$ go run main.go -word=opt
 
word:  opt
numb:  42
fork:  false
svar:  bar
tail:  []
```

注意，flag包要求执行命令时所有命令行flag参数都要出现在位置实参的前面，否则命令行flag参数将会被理解为位置实参，比如下面这种

```bash
$ go run main.go -word=opt a1 a2 a3 -fork=true
word:  opt
numb:  42
fork:  false
svar:  bar
tail:  [a1 a2 a3 -fork=true]
```

使用`-h`或者`--help`会获得自动生成的帮助文本

```bash
$ go run main.go -h                           
Usage of /var/folders/s6/300jn_t108gbkxlxtcvb7yy00000gn/T/go-build1935325460/b001/exe/main:
  -fork
        a bool
  -numb int
        an int (default 42)
  -svar string
        a string var (default "bar")
  -word string
        a string (default "Jude")
```

<br>

## **2. colorize flag**

```golang
type Color string
 
const (
	ColorBlack  Color = "\u001b[30m"
	ColorRed          = "\u001b[31m"
	ColorGreen        = "\u001b[32m"
	ColorYellow       = "\u001b[33m"
	ColorBlue         = "\u001b[34m"
	ColorReset        = "\u001b[0m"
)
 
func colorize(color Color, message string) {
	fmt.Println(string(color), message, string(ColorReset))
}
 
func main() {
	useColor := flag.Bool("color", false, "display colorized output")
	flag.Parse()
 
	if *useColor {
		colorize(ColorRed, "Hello, DigitalOcean!")
	}
	fmt.Println("Hello, DigitalOcean!")
}
```

运行程序，得到如下输出结果，发现输出被添加了颜色

```bash
$ go run boolean.go -color=true
Hello, DigitalOcean! [red]
Hello, DigitalOcean!
```

<br>

## **3. 读取文件**

```golang
func main() {
	var count int
	flag.IntVar(&count, "n", 5, "number of lines to read from the file")
	flag.Parse()
 
	var in io.Reader
	if filename := flag.Arg(0); filename != "" {
		f, err := os.Open(filename)
		if err != nil {
			fmt.Println("error opening file: err: ", err.Error())
			os.Exit(1)
		}
		defer f.Close()
		in = f
	} else {
		in = os.Stdin
	}
 
	buf := bufio.NewScanner(in)
	for i := 0; i < count; i++ {
		if !buf.Scan() {
			break
		}
		fmt.Println(buf.Text())
	}
 
	if err := buf.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "error reading: err:", err.Error())
	}
}
```

运行程序，默认读取5行的数据，我们就让其读取此文件即可

```bash
$ go run head.go -- head.go
package main
 
import (
        "bufio"
        "flag"
```

<br>

## **4. sub command**

```golang
func NewGreetCommand() *GreetCommand {
	gc := &GreetCommand{
		fs: flag.NewFlagSet("greet", flag.ContinueOnError),
	}
 
	gc.fs.StringVar(&gc.name, "name", "World", "name of the person to be greeted")
	return gc
}
 
type GreetCommand struct {
	fs   *flag.FlagSet
	name string
}
 
func (g *GreetCommand) Name() string {
	return g.fs.Name()
}
 
func (g *GreetCommand) Init(args []string) error {
	return g.fs.Parse(args)
}
 
func (g *GreetCommand) Run() error {
	fmt.Println("Hello", g.name, "!")
	return nil
}
 
type Runner interface {
	Init([]string) error
	Run() error
	Name() string
}
 
func root(args []string) error {
	if len(args) < 1 {
		return errors.New("You must pass a sub-command")
	}
 
	cmds := []Runner{
		NewGreetCommand(),
	}
 
	subcommand := os.Args[1]
	for _, cmd := range cmds {
		if cmd.Name() == subcommand {
			cmd.Init(os.Args[2:])
			return cmd.Run()
		}
	}
	return fmt.Errorf("Unknown subcommand: %s", subcommand)
}
 
func main() {
	if err := root(os.Args[1:]); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
```

```bash
$ ./subcommand 
You must pass a sub-command
$ ./subcommand greet
Hello World !
$ ./subcommand greet -name Sammy
Hello Sammy !
$ ./subcommand world            
Unknown subcommand: world
```

<br>

## **Reference**

* https://www.digitalocean.com/community/tutorials/how-to-use-the-flag-package-in-go
* https://github.com/kevinyan815/gocookbook/issues/36