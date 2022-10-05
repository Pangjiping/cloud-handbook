# **golang设计模式**

## **1. 创建型模式**

这些设计模式提供了一种在创建对象的同时隐藏创建逻辑的方式，而不是使用new运算符直接实例化这些对象

这使得程序在判断针对某个给定实例需要创建哪些对象时更加灵活

<br>

### **1.1 工厂模式**

在工厂模式中，我们在创建对象时不会对客户端暴露创建逻辑，而是通过使用一个共同的接口来指向新创建的对象

代码实现：
```golang
type API interface {
	Say(name string) string
}
 
// 核心逻辑
func NewAPI(t int) API {
	if t == 1 {
		return &hiAPI{}
	} else if t == 2 {
		return &helloAPI{}
	}
	return nil
}
 
type hiAPI struct{}
 
func (h *hiAPI) Say(name string) string {
	return fmt.Sprintf("hi %s", name)
}
 
type helloAPI struct{}
 
func (h *helloAPI) Say(name string) string {
	return fmt.Sprintf("hello %s", name)
}
```

我们通过一个通用的接口来顶一个两个对象的创建，通过传入参数的方式指定我们创建的是哪个对象，总结工厂模式的优缺点

优点：
* 一个调用者想创建一个对象，只需要知道其名称就可以
* 扩展性高，想要增加一个产品，只需要为`NewAPI()`增加一条逻辑即可
* 屏蔽产品的具体实现，调用者只关心产品的接口

缺点：
* 每次增加一个产品，都需要修改`NewAPI()`的逻辑

<br>

### **1.2 抽象工厂模式**

抽象工厂模式是围绕一个超级工厂创建其他工厂，超级工厂可以理解为其他工厂的工厂

在抽象工厂模式中，借口负责创建一个相关对象的工厂，不需要显示的指定他们的类，每个生成的工厂都可以提供对象

代码实现：
```golang
// OrderMainDAO 订单主记录
type OrderMainDAO interface {
	SaveOrderMain()
}
 
// OrderDetailDAO 订单详情记录
type OrderDetailDAO interface {
	SaveOrderDetail()
}
 
// DAOFactory 抽象工厂接口
type DAOFactory interface {
	CreateOrderMainDAO() OrderMainDAO
	CreateOrderDetailDAO() OrderDetailDAO
}
 
// RDBMainDAO 为关系型数据库的OrderMainDAO实现
type RDBMainDAO struct{}
 
// SaveOrderMain ...
func (r *RDBMainDAO) SaveOrderMain() {
	fmt.Println("rdb main save")
}
 
// RDBDetailDAO 为关系型数据库的OrderDetailDAO实现
type RDBDetailDAO struct{}
 
// SaveOrderDetail ...
func (r *RDBDetailDAO) SaveOrderDetail() {
	fmt.Println("rdb detail save")
}
 
// RDBDAOFactory 是RDB 抽象工厂实现
type RDBDAOFactory struct{}
 
func (r *RDBDAOFactory) CreateOrderMainDAO() OrderMainDAO {
	return &RDBMainDAO{}
}
func (r *RDBDAOFactory) CreateOrderDetailDAO() OrderDetailDAO {
	return &RDBDetailDAO{}
}
 
// XMLMainDAO XML存储
type XMLMainDAO struct{}
 
// SaveOrderMain ...
func (*XMLMainDAO) SaveOrderMain() {
	fmt.Println("xml main save")
}
 
// XMLDetailDAO XML存储
type XMLDetailDAO struct{}
 
// SaveOrderDetail ...
func (*XMLDetailDAO) SaveOrderDetail() {
	fmt.Println("xml detail save")
}
 
// XMLDAOFactory 是RDB抽象工厂实现
type XMLDAOFactory struct{}
 
func (*XMLDAOFactory) CreateOrderMainDAO() OrderMainDAO {
	return &XMLMainDAO{}
}
func (*XMLDAOFactory) CreateOrderDetailDAO() OrderDetailDAO {
	return &XMLDetailDAO{}
}
```

在代码中使用RDB和XML存储订单信息，抽象工厂分别就能生成相关的主订单信息和订单详情信息

如果业务逻辑中需要替换使用的时候只需要修改工厂函数相关的类就可以替换使用不同的存储方式了

下面简单看一下使用：
```golang
func getMainAndDetail(factoy DAOFactory) {
	factoy.CreateOrderMainDAO().SaveOrderMain()
	factoy.CreateOrderDetailDAO().SaveOrderDetail()
}
 
func ExampleRDBFactory() {
	var factory DAOFactory
	factory = &RDBDAOFactory{}
	getMainAndDetail(factory)
}
 
func ExampleXMLFactory() {
	var factory DAOFactory
	factory = &XMLDAOFactory{}
	getMainAndDetail(factory)
}
```

因为`RDBDAOFactory`和`XMLDAOFactory`均实现了抽象工厂接口`DAOFactory`，所以我们可以在工厂创建阶段传入任意一个想实现的存储方法

它们会对应不同的自己实现的Save方法

优点：
* 当一个产品家族中的多个对象被设计成一起工作时，它能保证客户端始终只使用同一个产品族中的对象

缺点：
* 产品族扩展非常困难，要增加一个系列的某一产品，既要在抽象工厂里面加代码，又要在具体实现里面加代码

<br>

### **1.3 单例模式**

单例模式设计一个单一的类，该类负责创建自己的对象，同时确保只有一个对象被创建

这个类提供了一种访问其唯一对象的方式，可以直接访问，不需要实例化该类的对象

单例模式的线程安全懒汉模式实现：
```golang
// Singleton 单例接口、可导出
// 通过该接口可以避免 GetInstance 返回一个包私有类型的指针
type Singleton interface {
	foo()
}
 
// singleton 私有单例类
type singleton struct {}
 
func (s singleton) foo(){}
 
var (
	instance *singleton
	once sync.Once
)
 
// GetInstance 获取单例对象
func GetInstance() Singleton{
	once.Do(func() {
		instance=&singleton{}
	})
	return instance
}
```

优点：
* 进程中只存在一个实例，内存消耗小，避免频繁销毁和创建
* 避免对资源的多重占用，比如文件

缺点：
* 没有接口，不能继承，与单一职责原则冲突

<br>

### **1.4 建造者模式**

存在一个类Builder会一步一步构造最终的对象，该Builder类是独立于其他对象的

首先我们需要定义一个生成器接口，这里面是产品的共同方法

然后需要一个向外部暴露的Director结构体，在结构体的`Construct()`方法中去调用所有的建造方法

我们可以选择将具体的建造方法隐藏，而只对外暴露一个`Construct()`方法提供整个建造流程的调用

```golang
// Builder 生成器接口
type Builder interface {
	part1()
	part2()
	part3()
}
 
type Director struct {
	builder Builder
}
 
func (d *Director) Construct() {
	d.builder.part1()
	d.builder.part2()
	d.builder.part3()
}
```

然后我们对外提供一个构建`Director`对象的方法

```golang
func NewDirector(builder Builder) *Director {
	return &Director{
		builder: builder,
	}
}
```

最后就是产品的具体实现，我们在此实现两个产品，这两个产品都需要实现`Builder`接口的三个方法

```golang
// 建造者一
type Builder1 struct {
	result string
}
 
func (b *Builder1) part1() {
	b.result += "1"
}
func (b *Builder1) part2() {
	b.result += "2"
}
func (b *Builder1) part3() {
	b.result += "3"
}
func (b *Builder1) GetResult() string {
	return b.result
}
 
// 建造者二
type Builder2 struct {
	result int
}
 
func (b *Builder2) part1() {
	b.result += 1
}
func (b *Builder2) part2() {
	b.result += 2
}
func (b *Builder2) part3() {
	b.result += 3
}
func (b *Builder2) GetResult() int {
	return b.result
}
```

在使用中，我们首先需要构建一个具体的建造者，比我我们构建一个建造者一对象

然后使用`NewDirector()`方法生成一个抽象的`Director`对象，然后调用`Construct()`方法来建造，最后调用建造者二本身的方法获取结果即可

```golang
func TestBuilder1(t *testing.T) {
	builder := &Builder1{}
	director := NewDirector(builder)
	director.Construct()
	res := builder.GetResult()
	if res != "123" {
		t.Fatalf("Builder1 fail expect 123 acture %s", res)
	}
}
```

优点：
* 建造者独立、易扩展
* 便于控制细节风险

缺点：
* 产品必须有共同点、范围有限制
* 内部变化复杂的话会有很多的建造类

<br>

### **1.5 原型模式**

原型模式用于创建重复的对象，同时又能保证性能

这种模式实现一个原型接口，该接口用于创建当前对象的克隆，当直接创建对象的代价比较大时，则采用这种模式

例如，一个对象需要在一个高代价的数据库操作之后被创建，我们可以缓存该对象，在下一个请求时返回它的克隆，在需要时更新数据库，以此来减少数据库调用

 

原型模式配合原型管理器使用，使得客户端在不知道具体类的情况下，通过接口管理器得到新的实例，并且包含部分预设配置

原型管理器的实现我们使用一个map，如果想要线程安全考虑使用sync.map

原型管理器提供了两个主要方法，分别是取得原型对象和存入/修改原型对象，值得注意的是原型对象必须自己实现`Cloneable`接口

```golang
// Cloneable 原型对象需要实现的接口，具体是一个Clone()方法，返回自身
type Cloneable interface {
	Clone() Cloneable
}
 
// PrototypeManager 存储原型对象
type PrototypeManager struct {
	prototypes map[string]Cloneable
}
 
func NewPrototypeManager() *PrototypeManager {
	return &PrototypeManager{
		prototypes: make(map[string]Cloneable),
	}
}
 
func (p *PrototypeManager) Get(name string) Cloneable {
	return p.prototypes[name].Clone()
}
 
func (p *PrototypeManager) Set(name string, prototype Cloneable) {
	p.prototypes[name] = prototype
}
```

我们看一下简单使用，我们先写一个原型类，他要实现`Cloneable`接口

```golang
type Type1 struct {
	name string
}
 
func (t *Type1) Clone() Cloneable {
	tc := *t
	return &tc
}
```

然后使用原型管理器管理这个对象

```golang
func main() {
	protoMgr := NewPrototypeManager()
	type1 := &Type1{name: "lucy"}
	protoMgr.Set("type1", type1)
	type2 := protoMgr.Get("type1")
	fmt.Println(type2.(*Type1).name)
}
```

优点：
* 性能提高
* 逃避构造函数的约束

缺点：
* 配备克隆方法需要对类的功能进行通盘考虑，特别是当一个类引用不支持串行化的间接对象，或者引用含有循环结构的时候
* 必须实现Cloneable接口

<br>

## **2. 结构型模式**

这些设计模式关注类和对象的组合

继承的概念被用来组合接口和定义组合对象获得新功能的方式

<br>

### **2.1 适配器模式**

适配器模式是作为两个不兼容的接口之间的桥梁

这种模式涉及到一个单一的类，该类负责加入独立的或者不兼容的接口功能，比如读卡器是作为内存卡和电脑之间的适配器

首先我们存在一个被适配的类`adaptee`，要使用一个适配器将其适配为目标类：

```golang
// Adaptee 被适配的目标接口
type Adaptee interface {
	SpecificRequest() string
}
 
// adapteeImpl 被适配的目标类
type adapteeImpl struct{}
 
// SpecificRequest 被适配的目标类方法
func (a *adapteeImpl) SpecificRequest() string {
	return "adaptee method"
}
 
// NewAdaptee 构建被适配目标类
func NewAdaptee() Adaptee {
	return &adapteeImpl{}
}
```

然后对于适配目标类`target`，我们定义一个适配器来实现适配

```golang
// Target 适配的目标接口
type Target interface {
	Request() string
}
 
// adapter 将adaptee -> target的适配器
type adapter struct {
	Adaptee
}
 
func (a *adapter) Request() string {
	return a.SpecificRequest()
}
 
func NewAdapter(adaptee Adaptee) Target {
	return &adapter{adaptee}
}
```

要记住我们的目标是什么？目标是在目标类中使用适配器来调用被适配类的方法，所以我们在使用时首先要实例化被适配类和适配类

```golang
adaptee := NewAdaptee()
target := NewAdapter(adaptee)
```

然后调用目标类的方法，就可以通过适配器来调用被适配类的方法了

```golang
res := target.Request() // adaptee method
if res != expect {
	t.Fatalf("expect: %s, actual: %s", expect, res)
}
```

优点：
* 可以让任何两个没有关联的类一起运行
* 提高了类的复用
* 增加了类的透明度
* 灵活性好

缺点：
* 过多的使用适配器会让整个系统很乱
* 不要过多适配，不要过多继承

<br>

### **2.2 桥接模式**

桥接模式适用于把抽象化与实现化解耦，使得二者可以独立变化

这种模式涉及到一个作为桥接的接口，使得实体类的功能独立于接口实现类，这两种类型的类可以被结构化改变而不相互影响

我们以发送验证码为例，需求是存在两种发送验证码的方式：短信和邮件，同时需要发送两类验证码：普通验证码和紧急验证码

在这种情况下，需要一个发送验证码的抽象接口和实现接口，实现接口负责实现两种发送方式，抽象接口负责实现两类验证码

首先来看实现接口：
```golang
// MessageImplementer 发送验证码的实现接口
type MessageImplementer interface {
	Send(text, to string)
}
 
// MessageSMS 发送手机验证码的实现类
type MessageSMS struct{}
func (m *MessageSMS) Send(text, to string) {
	fmt.Printf("send %s to %s via SMS\n", text, to)
}
func ViaSMS() MessageImplementer {
	return &MessageSMS{}
}
 
// MessageEmail 发送电子邮件验证码的实现类
type MessageEmail struct{}
func (m *MessageEmail) Send(text, to string) {
	fmt.Printf("send %s to %s via Email\n", text, to)
}
func ViaEmail() MessageImplementer {
	return &MessageEmail{}
}
```

然后是抽象接口
```golang
// AbstractMessage 发送验证码的抽象接口
type AbstractMessage interface {
	SendMessage(text, to string)
}
 
// CommonMessage 发送普通验证码的实现类，实现了抽象接口AbstractMessage
type CommonMessage struct {
	method MessageImplementer
}
func (m *CommonMessage) SendMessage(text, to string) {
	m.method.Send(text, to)
}
func NewCommonMessage(method MessageImplementer) *CommonMessage {
	return &CommonMessage{
		method: method,
	}
}
 
// UrgencyMessage 发送紧急验证码的实现类，实现了抽象接口AbstractMessage
type UrgencyMessage struct {
	method MessageImplementer
}
func (u *UrgencyMessage) SendMessage(text, to string) {
	u.method.Send(fmt.Sprintf("[Urgency] %s", text), to)
}
func NewUrgencyMessage(method MessageImplementer) *UrgencyMessage {
	return &UrgencyMessage{
		method: method,
	}
}
```

桥接模式的结构可以简单的看为实现接口和抽象接口分离，如果我们需要扩展发送验证码的方式比如APP内推送，可以只在实现接口那一部分增加一个实现类就可以

下面来看一下如何使用桥接模式

```golang
func ExampleCommonSMS() {
	m := NewCommonMessage(ViaSMS())
	m.SendMessage("have a drink?", "bob")
	// Output:
	// send have a drink? to bob via SMS
}
 
func ExampleCommonEmail() {
	m := NewCommonMessage(ViaEmail())
	m.SendMessage("have a drink?", "bob")
	// Output:
	// send have a drink? to bob via Email
}
```

优点：
* 抽象和实现的分离
* 优秀的扩展能力
* 实现细节对客户透明

缺点：
* 增加系统理解和设计的难度，要求对抽象层和实现层分别编程

<br>

### **2.3 组合模式**

组合模式又叫整体部分模式，用于把一组相似的对象当做一个单一的对象，组合模式根据树形结构来组合对象，用来表示部分以及整体层次

这种模式创建了一个包含对象组的类，该类提供了修改相同对象组的方式

首先定义一个接口，包含了我们需要的所有方法
```golang
const (
	LEAF_NODE = iota
	COMPOSITE_NODE
)
 
type Component interface {
	Parent() Component
	SetParent(component Component)
	Name() string
	SetName(s string)
	AddChild(component Component)
	Print(s string)
}
```

继而用一个实现类来实现这个接口
```golang
type component struct {
	parent Component
	name   string
}
 
func (c *component) Parent() Component {
	return c.parent
}
func (c *component) Name() string {
	return c.name
}
func (c *component) SetParent(component Component) {
	c.parent = component
}
func (c *component) SetName(name string) {
	c.name = name
}
func (c *component) AddChild(component Component) {}
func (c *component) Print(s string)               {}
```

现在让我们来组合对象
```golang
type Leaf struct {
	component
}
 
func (l *Leaf) Print(s string) {
	fmt.Printf("%s-%s\n", s, l.Name())
}
 
func NewLeaf() *Leaf {
	return &Leaf{}
}
```

```golang
type Composite struct {
	component
	childs []Component
}
 
func (c *Composite) AddChild(component Component) {
	component.SetParent(c)
	c.childs = append(c.childs, component)
}
func (c *Composite) Print(s string) {
	fmt.Printf("%s+%s\n", s, c.Name())
	s += " "
	for _, comp := range c.childs {
		comp.Print(s)
	}
}
 
func NewComposite() *Composite {
	return &Composite{
		childs: make([]Component, 0),
	}
}
```

定义一个统一的实例化方法

```golang
func NewComponent(kind int, name string) Component {
	var c Component
	switch kind {
	case LEAF_NODE:
		c = NewLeaf()
	case COMPOSITE_NODE:
		c = NewComposite()
	}
	c.SetName(name)
	return c
}
```

在使用时，需要将这些方法组成一个树形结构：

```golang
func ExampleComposite() {
	root := NewComponent(COMPOSITE_NODE, "root")
	c1 := NewComponent(COMPOSITE_NODE, "c1")
	c2 := NewComponent(COMPOSITE_NODE, "c2")
	c3 := NewComponent(COMPOSITE_NODE, "c3")
 
	l1 := NewComponent(LEAF_NODE, "l1")
	l2 := NewComponent(LEAF_NODE, "l2")
	l3 := NewComponent(LEAF_NODE, "l3")
 
	root.AddChild(c1)
	root.AddChild(c2)
	c1.AddChild(c3)
	c1.AddChild(l1)
	c2.AddChild(l2)
	c2.AddChild(l3)
 
	root.Print("")
	// Output:
	// +root
	//  +c1
	//   +c3
	//   -l1
	//  +c2
	//   -l2
	//   -l3
}
```

优点：
* 高层模块调用简单
* 节点自由增加

缺点：
* 在使用组合模式时，其叶子和树枝的声明都是实现类，而不是接口，违反了依赖倒置原则

<br>

### **2.4 代理模式**

在代理模式中，一个类代表另一个类的功能，我们创建现有对象的对象，以便向外界提供功能接口

代理模式用于延迟处理操作或者在进行实际操作前后进行其它处理

我们首先定义一组对象接口及其实现类
```golang
// Subject 对象接口
type Subject interface {
	Do() string
}
 
// RealSubject 接口的实现类
type RealSubject struct{}
 
func (r RealSubject) Do() string {
	return "real"
}
```

然后定义一个代理类，在代理类中对对象接口的方法在调用前和调用后进行一系列处理

```golang
// Proxy 代理类
type Proxy struct {
	real RealSubject
}
 
func (p Proxy) Do() string {
	var res string
 
	// 在调用真是对象之前的工作，检查缓存，判断权限，实例化真实对象等
	res += "pre:"
 
	// 调用真实对象
	res += p.real.Do()
 
	// 调用之后的操作，如缓存结果，对结果进行进一步处理等
	res += ":after"
	return res
}
```

如何使用代理模式？在外界看来，`Proxy`类完全代理了`RealSubject`类，而二者都实现了`Subject`接口，所以我们只需要实例化一个代理类`Proxy`

在调用代理类实现的方法时，就会调用对象类所实现的方法，并且在代理类中做了进一步的封装

```golang
var sub Subject
sub = &Proxy{}
 
res := sub.Do()
 
if res != "pre:real:after" {
    fmt.Println("error")
}
```

优点：
* 职责清晰
* 高扩展性
* 智能化

缺点：
* 增加了客户端和服务端之间的中间层，处理请求可能会变慢
* 实现代理模式需要额外的工作，有些代理模式的实现非常负责

<br>

### **2.5 装饰模式**

装饰器模式允许向一个现有的对象添加新的功能，同时又不改变其结构

这种模式提供了一个装饰类，用来包装原有的类，并在保持类方法签名完整的前提下，提供了额外的功能

Go语言借助于匿名组合和非入侵式接口可以很方便的实现装饰模式，使用匿名组合时，在装饰器中不必显示定义转调原对象方法

在装饰模式中，首先定义被装饰的接口及其实现类：
```golang
// Component 目标接口
type Component interface {
	Calc() int
}
 
// ConcreteComponent 被装饰的类
type ConcreteComponent struct{}
func (c *ConcreteComponent) Calc() int {
	return 0
}
```

然后我们定义一个乘法装饰器，其匿名组合了目标接口`Component`，并且自身又实现了这个接口

```golang
// MulDecorator 乘法装饰类
type MulDecorator struct {
	Component
	num int
}
func (m *MulDecorator) Calc() int {
	return m.Component.Calc() * m.num
}
 
func WarpMulDecorator(c Component, num int) Component {
	return &MulDecorator{
		Component: c,
		num:       num,
	}
}
```

同样地，我们也可以实现一个加法装饰类

```golang
type AddDecorator struct {
	Component
	num int
}
func (a *AddDecorator) Calc() int {
	return a.Component.Calc() + a.num
}
 
func WrapAddDecorator(c Component, num int) Component {
	return &AddDecorator{
		Component: c,
		num:       num,
	}
}
```

关于装饰器的使用，首先实例化一个目标类，然后调用装饰器即可

```golang
var c Component = &ConcreteComponent{}
c = WarpAddDecorator(c, 10)
c = WarpMulDecorator(c, 8)
res := c.Calc()
 
fmt.Printf("res %d\n", res)
// Output:
// res 80
```

优点：
* 装饰类和被装饰类可以独立发展，完全解藕
* 装饰模式是继承的一个替代模式，装饰模式可以动态扩展一个实现类的功能

缺点：
* 多层装饰会使得代码结构变的复杂

<br>

### **2.6 享元模式**

享元模式主要用于减少创建对象的数量，以减少内存占用和提升性能

享元模式尝试重用现有的同类对象，如果未找到匹配的对象，则重新创建对象

首先我们创建一个享元模式的工厂和单例对象，并且向外界暴露两个接口：获取单例对象和获取map中的对象

```golang
type ImageFlyweightFactory struct {
	maps map[string]*ImageFlyweight
}
 
var imageFactory *ImageFlyweightFactory
 
func GetImageFlyweightFactory() *ImageFlyweightFactory {
	if imageFactory == nil {
		imageFactory = &ImageFlyweightFactory{
			maps: make(map[string]*ImageFlyweight),
		}
	}
	return imageFactory
}
 
func (i *ImageFlyweightFactory) Get(filename string) *ImageFlyweight {
	image := i.maps[filename]
	if image == nil {
		image := NewImageFlyweight(filename)
		i.maps[filename] = image
	}
	return image
}
```

对于map中的对象类，我们可以简单模拟一个读写文件的操作

```golang
type ImageFlyweight struct {
	data string
}
func (i *ImageFlyweight) Data() string {
	return i.data
}
 
func NewImageFlyweight(filename string) *ImageFlyweight {
	data := fmt.Sprintf("image data %s", filename)
	return &ImageFlyweight{
		data: data,
	}
}
```

这样我们就不必频繁去读取某个文件的数据，而是使用一个map将这些与文件数据关联的对象保存起来，如果调用一个已经存在的对象则直接从map中获得即可

优点：
* 大大减少对象的创建，降低内存分配，提升效率

缺点：
* 提升了系统的复杂度，需要分离出外部状态和内部状态，而且外部状态具有固有化的性质，不应该随着内部状态的变化而变化，否则会造成系统的混乱

<br>

### **2.7 外观模式**

外观模式隐藏系统的复杂性，并向客户端提供了一个可以访问系统的接口

这种模式涉及到一个单一的类，该类提供了客户端请求的简化方法和对现有系统类方法的委托调用

facade模块同时暴露了a和b两个Module的NewXXX和interface，其它代码如果需要使用细节功能时可以直接调用

现在我们有两个常规的接口及其实现类`AModuleAPI`和`BModuleAPI`
```golang
//AModuleAPI ...
type AModuleAPI interface {
	TestA() string
}
 
//NewAModuleAPI return new AModuleAPI
func NewAModuleAPI() AModuleAPI {
	return &aModuleImpl{}
}
 
type aModuleImpl struct{}
func (*aModuleImpl) TestA() string {
	return "A module running"
}
 
//BModuleAPI ...
type BModuleAPI interface {
	TestB() string
}
 
//NewBModuleAPI return new BModuleAPI
func NewBModuleAPI() BModuleAPI {
	return &bModuleImpl{}
}
 
type bModuleImpl struct{}
func (*bModuleImpl) TestB() string {
	return "B module running"
}
```

对于外观模式而言，我们需要提供一个统一接口来访问这两个常规接口

值得注意的是，虽然我们在其他package中实例化api对象时可以只调用`NewAPI()`方法，但是我们仍然将`NewAModuleAPI()`和`NewBModuleAPI()`接口暴露出来，目的是用户可以做一些内部实现的查看

```golang
type API interface {
	Test() string
}
 
type apiImpl struct {
	a AModuleAPI
	b BModuleAPI
}
 
func (a *apiImpl) Test() string {
	aRet := a.a.TestA()
	bRet := a.b.TestB()
	return fmt.Sprintf("%s\n%s", aRet, bRet)
}
 
func NewAPI() API {
	return &apiImpl{
		a: NewAModuleAPI(),
		b: NewBModuleAPI(),
	}
}
```

我们来看一下如何使用外观模式，因为API接口已经提供给我们了调用两个对象类的统一接口，我么只需要实例化`API`就可以
```golang
api := NewAPI()
ret := api.Test()
```

优点：
* 减少系统的相互依赖
* 提高灵活性
* 提升安全性

缺点：
* 不符合开闭原则，如果发生改动会很麻烦，继承重写都不合适

<br>

## **3. 行为型模式**

行为型模式特别关注对象之间的通信

<br>

### **3.1 中介者模式**

中介者模式用来降低多个对象之间的通信复杂性

这种模式提供了一个中介类，该类通常处理不同类之间的通信，并支持松耦合，使得代码易于维护

现在我们模拟一个CPU和移动硬盘或者CD通信的场景，首先定义一个驱动类，用于读取CD的数据

```golang
// CDDriver CD驱动类，读取CD数据
type CDDriver struct {
	Data string
}
func (c *CDDriver) ReadData() {
	c.Data = "music,image"
	fmt.Printf("CDDriver: reading data %s\n", c.Data)
	GetMediatorInstance().changed(c)
}
```

对于读取到的数据，CPU做处理，将数据分为音频数据和视频数据，同时定义声卡类和显卡类用于音频和视频的显示

```golang
// CPU 处理读入的数据
type CPU struct {
	Video string
	Sound string
}
func (c *CPU) Process(data string) {
	sp := strings.Split(data, ",")
	c.Sound = sp[0]
	c.Video = sp[1]
 
	fmt.Printf("CPU: split data with Sound %s, Video %s\n", c.Sound, c.Video)
	GetMediatorInstance().changed(c)
}
 
// VideoCard 显卡类，用于播放视频数据
type VideoCard struct {
	Data string
}
func (v *VideoCard) Display(data string) {
	v.Data = data
	fmt.Printf("VideoCard: display %s\n", v.Data)
	GetMediatorInstance().changed(v)
}
 
// SoundCard 声卡类，播放音频数据
type SoundCard struct {
	Data string
}
func (s *SoundCard) Play(data string) {
	s.Data = data
	fmt.Printf("SoundCard: play %s\n", s.Data)
	GetMediatorInstance().changed(s)
}
```

根据目前已经写了的代码来看，主要有两大类：外部设备驱动和CPU处理

所以中介模式的作用就是将这两个大类连起来，那么怎么做中介模式呢？我们只需要定义一个中介类包含所有已有的对象，同时根据传入对象的类型来判断此时执行外部驱动还是CPU逻辑就可以

我们使用单例模式生成中介者，同时使用switch语句完成类型判断，主要就是这两种类型

```golang
// Mediator 中介类
type Mediator struct {
	CD    *CDDriver
	Cpu   *CPU
	Video *VideoCard
	Sound *SoundCard
}
func (m *Mediator) changed(i interface{}) {
	switch inst := i.(type) {
	case *CDDriver:
		m.Cpu.Process(inst.Data)
	case *CPU:
		m.Sound.Play(inst.Sound)
		m.Video.Display(inst.Video)
	}
}
 
var mediator *Mediator
// GetMediatorInstance 获取单例对象
func GetMediatorInstance() *Mediator {
	if mediator == nil {
		mediator = &Mediator{}
	}
	return mediator
}
```

在使用中介模式时，我们需要挨个实例化中介类中所有的对象，个人感觉这种写法并不是很好

```golang
mediator := GetMediatorInstance()
mediator.CD = &CDDriver{}
mediator.CPU = &CPU{}
mediator.Video = &VideoCard{}
mediator.Sound = &SoundCard{}
 
//Tiggle
mediator.CD.ReadData()
```

优点：
* 降低了类的复杂性，将一对多转化成了一对一
* 各个类之间的解耦
* 符合迪米特原则

缺点：
* 中介者会庞大，变得复杂难以维护

<br>

### **3.2 观察者模式**

当对象存在一对多关系时，则使用观察者模式

比如，当一个对象呗修改时，则会自动通知依赖它的对象

我们首先定义一个最简单的被观察的对象，其需要维护一个与它关联的观察者列表，同时实现通知、绑定观察者等一系列方法

```golang
// Subject 目标类，被观察对象
type Subject struct {
	observers []Observer // 观察者列表
	context   string     // 上下文信息
}
 
// Attach 绑定某个观察者
func (s *Subject) Attach(o Observer) {
	s.observers = append(s.observers, o)
}
// notify 通知观察者变更信息
func (s *Subject) notify() {
	for _, o := range s.observers {
		o.Update(s)
	}
}
// UpdateContext 变更自己的上下文信息，并通知观察者变更
func (s *Subject) UpdateContext(ctx string) {
	s.context = ctx
	s.notify()
}
 
func NewSubject() *Subject {
	return &Subject{
		observers: make([]Observer, 0),
	}
}
```

然后我们定义一个观察者接口和其实现类

```golang
// Observer 观察者接口
type Observer interface {
	Update(s *Subject)
}
 
// 其中一个观察者的实现类
type Reader struct {
	name string
}
func (r *Reader) Update(s *Subject) {
	fmt.Printf("%s receive %s\n", r.name, s.context)
}
 
func NewReader(name string) Observer {
	return &Reader{name: name}
}
```

代码可以很清晰的看出来，当我们变更被观察者的上下文信息时，其将会将变更信息推送至所有的观察者

我们可以绑定多个`Reader`观察者，来看一下被观察者上下文变更通知的实现

```golang
func ExampleObserver() {
	subject := NewSubject()
	reader1 := NewReader("reader1")
	reader2 := NewReader("reader2")
	reader3 := NewReader("reader3")
	subject.Attach(reader1)
	subject.Attach(reader2)
	subject.Attach(reader3)
 
	subject.UpdateContext("observer mode")
	// Output:
	// reader1 receive observer mode
	// reader2 receive observer mode
	// reader3 receive observer mode
}
```

优点：
* 观察者和被观察者是抽象耦合的
* 建立一套触发机制

缺点：
* 如果一个被观察者对象有很多直接和间接的观察者的话，将所有的观察者都通知到需要一定的时间成本
* 如果观察者和观察目标之间有循环依赖的话，观察目标会触发他们之间的循环调用，可能使系统崩溃
* 观察者模式没有相应的机制让观察者知道所观察的目标对象是怎么发生变化的，而仅仅知道观察目标发生了变化

<br>

### **3.3 命令模式**

命令模式是一种数据驱动的设计模式

请求以命令的形式包裹在对象中，并上传给调用对象。调用对象寻找可以处理该命令的合适的对象，并把命令传给相应的对象，该对象执行命令

命令模式的本质就是把某个对象的方法调用封装到对象中，方便传递、存储、调用

让我们考虑这样一个场景：一台电脑的启动和重启，需要主板类、按键类、命令类的参与

首先定义一个抽象的命令接口，其中有两个具体实现类

```golang
// Command 命令抽象接口
type Command interface {
	Execute()
}
 
// StartCommand 开机命令类
type StartCommand struct {
	mb *MotherBoard
}
func (s *StartCommand) Execute() {
	s.mb.Start()
}
 
func NewStartCommand(mb *MotherBoard) Command {
	return &StartCommand{
		mb: mb,
	}
}
 
// RebootCommand 重启命令类
type RebootCommand struct {
	mb *MotherBoard
}
func (r *RebootCommand) Execute() {
	r.mb.Reboot()
}
 
func NewRebootCommand(mb *MotherBoard) Command {
	return &RebootCommand{
		mb: mb,
	}
}
```

然后设计主板类，主板需要有两个方法：开机和重启

```golang
// MotherBoard 主板类，命令的具体执行类
type MotherBoard struct{}
 
func (m *MotherBoard) Start() {
	fmt.Println("system starting")
}
func (m *MotherBoard) Reboot() {
	fmt.Println("system rebooting")
}
```

最后实现按钮类，按钮类只是定义了两个按钮所执行的对象的方法，而具体执行哪个对象的方法需要我们自己指定

```golang
// Box 按钮类
type Box struct {
	button1 Command
	button2 Command
}
func (b *Box) PressButton1() {
	b.button1.Execute()
}
func (b *Box) PressButton2() {
	b.button2.Execute()
}
 
func NewBox(button1, button2 Command) *Box {
	return &Box{
		button1: button1,
		button2: button2,
	}
}
```

在使用中，我们让第一个机箱`box1`的按钮1是开机，按钮2是重启；`box2`的按钮1是重启，按钮2是开机

```golang
func ExampleCommand() {
	mb := &MotherBoard{}
	startCommand := NewStartCommand(mb)
	rebootCommand := NewRebootCommand(mb)
 
	box1 := NewBox(startCommand, rebootCommand)
	box1.PressButton1()
	box1.PressButton2()
 
	box2 := NewBox(rebootCommand, startCommand)
	box2.PressButton1()
	box2.PressButton2()
	// Output:
	// system starting
	// system rebooting
	// system rebooting
	// system starting
}
```

优点：
* 降低了系统耦合度
* 新的命令可以很容易添加到系统中去

缺点：
* 使用命令模式可能会导致某些系统有过多的具体命令类

<br>

### **3.4 迭代器模式**

迭代器模式用于顺序访问集合对象的元素，不需要知道集合对象的底层表示

在迭代器模式中，我们需要定义一个聚合对象接口和迭代器接口，之后所有加入的聚合对象都需要实现迭代器方法

```golang
// Aggregate 聚合对象抽象接口，聚合对象需要实现迭代器
type Aggregate interface {
	Iterator() Iterator
}
 
// Iterator 迭代器抽象接口，至少有以下三个方法
type Iterator interface {
	First()            // 第一个元素
	IsDone() bool      // 是否结束
	Next() interface{} // 下一个元素
}
```

现在我们实现一个聚合对象的类，这个类必须实现迭代器方法

```golang
// Numbers 一个聚合对象
type Numbers struct {
	start, end int
}
func (n *Numbers) Iterator() Iterator {
	return &NumberIterator{
		numbers: n,
		next:    n.start,
	}
}
```

然后来实现它的迭代器类，迭代器类至少需要实现迭代器抽象接口定义的所有方法

```golang
// NumberIterator Number聚合对象的迭代器类
type NumberIterator struct {
	numbers *Numbers
	next    int
}
 
func (n *NumberIterator) First() {
	n.next = n.numbers.start
}
func (n *NumberIterator) IsDone() bool {
	return n.next > n.numbers.end
}
func (n *NumberIterator) Next() interface{} {
	if !n.IsDone() {
		next := n.next
		n.next++
		return next
	}
	return nil
}
```

关于迭代器的使用在C++和java中非常多，C++的STL容器就是通过迭代器来访问的

我们只需要声明一个聚合对象，然后使用迭代器来遍历它就可以了

在此我们在定义一个使用迭代器遍历打印的函数

```golang
func IteratorPrint(i Iterator) {
	for i.First(); !i.IsDone(); {
		c := i.Next()
		fmt.Printf("%#v\n", c)
	}
}
```

```golang
func ExampleIterator() {
	var aggregate Aggregate
	aggregate = NewNumbers(1, 10)
 
	IteratorPrint(aggregate.Iterator())
	// Output:
	// 1
	// 2
	// 3
	// 4
	// 5
	// 6
	// 7
	// 8
	// 9
	// 10
}
```

优点：
* 支持以不同的方式遍历一个聚合对象
* 迭代器简化了聚合类
* 在同一个聚合上可以有很多遍历
* 在迭代器模式中，新增加的聚合类和迭代器类都很方便，无需修改原有代码

缺点：
* 由于迭代器模式将存储数据和遍历数据的指责分离，新增加的聚合类需要对应增加新的迭代器类，类的个数成对增加，这在一定程度上增加了系统的复杂性

<br>

### **3.5 模版方法模式**

在模版模式中，一个抽象类公开定义了执行它的方法/模版，它的子类可以按需重写方法实现，但调用将以抽象类中定义的方式进行

```golang
// Downloader 下载器抽象接口
type Downloader interface {
	Download(uri string)
}
// implement 实现接口
type implement interface {
	download()
	save()
}
 
// template 模板类
type template struct {
	implement
	uri string
}
 
func (t *template) Download(uri string) {
	t.uri = uri
	fmt.Println("prepare downloading")
	t.implement.download()
	t.implement.save()
	fmt.Println("finish downloading")
}
func (t *template) save() {
	fmt.Println("default save")
}
 
// newTemplate 实例化一个模板需要implement接口的实现
func newTemplate(impl implement) *template {
	return &template{
		implement: impl,
	}
}
 
// HTTPDownloader HTTP下载器类
type HTTPDownloader struct {
	*template
}
func (d *HTTPDownloader) download() {
	fmt.Printf("download %s via http\n", d.uri)
}
func (*HTTPDownloader) save() {
	fmt.Printf("http save\n")
}
 
func NewHTTPDownloader() Downloader {
	downloader := &HTTPDownloader{}
	temp := newTemplate(downloader)
	downloader.template = temp
	return downloader
}
 
// FTPDownloader FTP下载器类
type FTPDownloader struct {
	*template
}
func (d *FTPDownloader) download() {
	fmt.Printf("download %s via ftp\n", d.uri)
}
 
func NewFTPDownloader() Downloader {
	downloader := &FTPDownloader{}
	template := newTemplate(downloader)
	downloader.template = template
	return downloader
}
```

```golang
var downloader Downloader = NewHTTPDownloader()
 
downloader.Download("http://example.com/abc.zip")
// Output:
// prepare downloading
// download http://example.com/abc.zip via http
// http save
// finish downloading
```

优点：
* 封装不变部分，扩展可变部分
* 提取公公带吗，便于维护
* 行为由父类控制，子类实现

缺点：
* 每一个不同的实现都需要一个子类，导致子类数量增加

<br>

### **3.6 策略模式**

在策略模式中，一个类的行为或其算法可以在运行时更改

在策略模式中，我们创建表示各种策略的对象和一个行为随着策略对象改变而改变的context对象，策略对象改变context对象的执行算法

我们模拟一个支付场景，可选择的支付方式为现金和银行转账

我们首先需要定义一个总体的支付类，其中包含了可能的支付方式和账户上下文信息

```golang
// Payment 支付类
type Payment struct {
	context  *PaymentContext // 上下文信息（金额和卡号等）
	strategy PaymentStrategy // 支付方式
}
func (p *Payment) Pay() {
	p.strategy.Pay(p.context)
}
 
func NewPayment(name, cardid string, money int, strategy PaymentStrategy) *Payment {
	return &Payment{
		context: &PaymentContext{
			Name:   name,
			CardID: cardid,
			Money:  money,
		},
		strategy: strategy,
	}
}
 
// PaymentContext 支付上下文信息
type PaymentContext struct {
	Name, CardID string
	Money        int
}
```

然后我们定义支付方式的抽象接口，之后天机任意的支付方式只需要实现这个接口即可

```golang
// PaymentStrategy 支付方式抽象接口
type PaymentStrategy interface {
	Pay(*PaymentContext)
}
```

进而添加现金支付和银行转账的方式

```golang
// Cash 现金类，需要实现 PaymentStrategy 接口
type Cash struct{}
func (*Cash) Pay(ctx *PaymentContext) {
	fmt.Printf("Pay $%d to %s by cash", ctx.Money, ctx.Name)
}
 
// Bank 银行类，需要实现 PaymentStrategy 接口
type Bank struct{}
func (*Bank) Pay(ctx *PaymentContext) {
	fmt.Printf("Pay $%d to %s by bank account %s", ctx.Money, ctx.Name, ctx.CardID)
 
}
```

在使用策略模式时，我们只需要通过对外暴露的NewPayment()函数使用不同的支付方式的实现进行初始化，就可以调用相应的方法了

```golang
func ExamplePayByCash() {
	payment := NewPayment("Ada", "", 123, &Cash{})
	payment.Pay()
	// Output:
	// Pay $123 to Ada by cash
}
```

优点：
* 算法可以自由切换
* 避免使用多重条件判断
* 扩展性良好

缺点：
* 策略类会增多
* 所有策略类都需要对外暴露

<br>

### **3.7 状态模式**

在状态模式中，类的行为是基于它的状态而改变的

我们创建表示各种状态的对象和一个行为随着状态改变而改变的context对象

首先我们定义一个`DayContext`类：

```golang
type DayContext struct {
	today Week
}
func (d *DayContext) Today() {
	d.today.Today()
}
func (d *DayContext) Next() {
	d.today.Next(d)
}
 
func NewDayContext() *DayContext {
	return &DayContext{
		today: &Sunday{},
	}
}
```

其次我们用每一个类来表示每一种状态的变化，首先是一个通用的接口类型：

```golang
type Week interface {
	Today()
	Next(*DayContext)
}
```

```golang
type Sunday struct{}
func (*Sunday) Today() {
	fmt.Printf("Sunday\n")
}
func (*Sunday) Next(ctx *DayContext) {
	ctx.today = &Monday{}
}
 
type Monday struct{}
func (*Monday) Today() {
	fmt.Printf("Monday\n")
}
func (*Monday) Next(ctx *DayContext) {
	ctx.today = &Tuesday{}
}
 
type Tuesday struct{}
func (*Tuesday) Today() {
	fmt.Printf("Tuesday\n")
}
func (*Tuesday) Next(ctx *DayContext) {
	ctx.today = &Wednesday{}
}
 
type Wednesday struct{}
func (*Wednesday) Today() {
	fmt.Printf("Wednesday\n")
}
func (*Wednesday) Next(ctx *DayContext) {
	ctx.today = &Thursday{}
}
 
type Thursday struct{}
func (*Thursday) Today() {
	fmt.Printf("Thursday\n")
}
func (*Thursday) Next(ctx *DayContext) {
	ctx.today = &Friday{}
}
 
type Friday struct{}
func (*Friday) Today() {
	fmt.Printf("Friday\n")
}
func (*Friday) Next(ctx *DayContext) {
	ctx.today = &Saturday{}
}
 
type Saturday struct{}
func (*Saturday) Today() {
	fmt.Printf("Saturday\n")
}
func (*Saturday) Next(ctx *DayContext) {
	ctx.today = &Sunday{}
}
```

```golang
func ExampleWeek() {
	ctx := NewDayContext()
	todayAndNext := func() {
		ctx.Today()
		ctx.Next()
	}
 
	for i := 0; i < 8; i++ {
		todayAndNext()
	}
	// Output:
	// Sunday
	// Monday
	// Tuesday
	// Wednesday
	// Thursday
	// Friday
	// Saturday
	// Sunday
}
```

优点：
* 封装了转换规则
* 枚举可能的状态，在枚举状态之前需要确定状态种类
* 将所有与某个状态有关的行为放到一个类中，并且可以方便地增加新的状态，只需要改变对象状态即可改变对象的行为
* 允许状态转换逻辑与状态对象合为一体，而不是某一个巨大的条件语句块
* 可以让多个环境对象共享一个状态对象，从而减少系统中对象的个数

缺点：
* 状态模式的使用必然会增加系统类和对象的个数
* 状态模式的结构与实现都较为复杂，如果使用不当将导致程序结构和代码的混乱
* 状态模式对"开闭原则"的支持并不太好，对于可以切换状态的状态模式，增加新的状态类需要修改那些负责状态转换的源代码，否则无法切换到新增状态，而且修改某个状态类的行为也需修改对应类的源代码

<br>

### **3.8 备忘录模式**

备忘录模式保存一个对象的某个状态，以便在适当的时候恢复对象

我们需要定义一个备忘录接口及其具体实现

```golang
type Memento interface{}
 
type gameMemeto struct {
	hp, mp int
}
```

模拟一个游戏场景，需要一个备忘录来记录上一个状态的hp和mp，如果需要记录多个状态需要一个数组或者链表来存储`gameMemeto`对象即可

```golang
type Game struct {
	hp, mp int
	memo   Memento
}
 
func (g *Game) Play(mpDelta, hpDelta int) {
	g.mp += mpDelta
	g.hp += hpDelta
}
func (g *Game) Save() {
	g.memo = &gameMemeto{
		hp: g.hp,
		mp: g.mp,
	}
}
func (g *Game) Load() {
	gm := g.memo.(*gameMemeto)
	g.mp = gm.mp
	g.hp = gm.hp
}
func (g *Game) Status() {
	fmt.Printf("Current HP: %d, MP: %d\n", g.hp, g.mp)
}
```

优点：
* 给用户提供了一种可以恢复状态的机制，可以使用户能够比较方便地回道某个历史的状态
* 实现了信息的封装，使得用户不需要关系状态的保存细节

缺点：
* 消耗资源，存储状态可能需要大量的内存

<br>

### **3.9 解释器模式**

解释器模式提供了评估语言的语法或者表达式的方式

这种模式实现了一个表达式接口，该接口解释一个特定的上下文，这种模式被用在SQL解析、符号处理引擎等

首先我们需要定义一个抽象接口和三个负责处理数值的实现类

```golang
// Node node抽象接口
type Node interface {
	Interpret() int
}
 
// ValNode 负责赋值的类
type ValNode struct {
	val int
}
func (v *ValNode) Interpret() int {
	return v.val
}
 
// AddNode 负责加法运算的类
type AddNode struct {
	left, right Node
}
func (a *AddNode) Interpret() int {
	return a.left.Interpret() + a.right.Interpret()
}
 
// MinNode 负责减法运算的类
type MinNode struct {
	left, right Node
}
func (m *MinNode) Interpret() int {
	return m.left.Interpret() + m.right.Interpret()
}
```

然后定义一个解释器，解释器需要做的事情就是解析一个表达式，然后调用节点相关的方法

```golang
// Parser 解释器类
type Parser struct {
	exp   []string
	index int
	prev  Node
}
 
// Parse 解析表达式方法
func (p *Parser) Parse(exp string) {
	p.exp = strings.Split(exp, " ")
	for {
		if p.index >= len(p.exp) {
			return
		}
 
		switch p.exp[p.index] {
		case "+":
			p.prev = p.newAddNode()
		case "-":
			p.prev = p.newMinNode()
		default:
			p.prev = p.newValNode()
		}
	}
}
 
// newAddNode 加法运算
func (p *Parser) newAddNode() Node {
	p.index++
	return &AddNode{
		left:  p.prev,
		right: p.newValNode(),
	}
}
// newMinNode 减法运算
func (p *Parser) newMinNode() Node {
	p.index++
	return &MinNode{
		left:  p.prev,
		right: p.newValNode(),
	}
}
func (p *Parser) newValNode() Node {
	v, _ := strconv.Atoi(p.exp[p.index])
	p.index++
	return &ValNode{v}
}
 
func (p *Parser) Result() Node {
	return p.prev
}
```

如果不使用解释器模式，我们在调用上面定义的三个实现类的时候需要探究源码实现，而现在我们只需要简单实例化一个解释器对象，就可以达到这一目的

```golang
p := &Parser{}
p.Parse("1 + 2 + 3 - 4 + 5 - 6")
res := p.Result().Interpret()
fmt.Println(res)
// output: 1
```

优点：
* 可扩展性比较好，灵活
* 增加了新的解释表达式的方式
* 易于实现简答文法

缺点：
* 可利用常见比较少
* 对于复杂的文法比较难维护
* 解释器模式会引起类膨胀
* 解释器模式通常采用递归调用的方法

<br>