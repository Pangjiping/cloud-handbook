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