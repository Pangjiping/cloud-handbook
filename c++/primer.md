# C++ Primer Plus学习笔记

本笔记主要记录在《C++ Primer Plus》这本书的学习中，遇到的一些细节性问题，并辅以代码演示示例



## 1 处理数据

本节主要讨论以下几个方面的内容

- **const 限定符**
- **类型转换**
- 栈区：由编译器自动分配释放, 存放函数的参数值,局部变量等
- 堆区：由程序员分配和释放,若程序员不释放,程序结束时由操作系统回收





### 1.1 const 限定符

**1.1.1命名规则：**

​	创建常量的通用格式如下：

```c++
const type name = value;

// 注意：应该在声明中对const进行初始化，而不允许赋值行为
// 下面的代码是一个错误示例
const int toes;
toes=10;
```



**const相比于C语言风格的#define要更好，有以下三点：**

1）const限定符可以明确指明变量的类型；

2）可以使用C++的作用域规则将定义限制在特点的函数或文件中；

3）可以将const用于更复杂的数据结构中，比如函数的形参定义等等。



const限定符在函数声明中的使用待添加








### 1.2 类型转换

​		为了处理潜在的数据类型混乱问题，C++自动执行很多类型的转换：

​		（1）将一种算数类型的值赋给另一种算数类型的变量时，C++将对值进行转换；

​		（2）表达式中包含不同的类型时，C++将对值进行转换；

​		（3）将参数传递给函数时，C++将对值进行转换。



**1.2.1 初始化和赋值进行的转换**

​		将一个值赋值给值取值范围更大的类型通常不会导致什么问题。例如将 short 赋值给 long 变量并不会改变这个值，只是占用了更多字节而已。然而，将一个很大的 long 值赋值给 float 变量将降低精度，因为 float 只有6位有效数字。

​		下面是以下潜在的数值转换问题：

​		（1）将较大的浮点类型转换为较小的浮点类型，如将 double 转换成 float ，潜在的问题是精度（有效位数）降低，值可能超出目标类型的取值范围，在这种情况下，结果将是不确定的。

​		（2）将浮点数转换为整形，小数部分会丢失，原来的值可能超出目标类型的取值范围，在这种情况下，结果将是不确定的。

​		（3）将较大的整形类型转换为较小的整形类型，如将 long 转换为 short，原来的值可能超出目标类型的取值范围，通常只复制右边的字节。



**1.2.2 以{ }方式在初始化时进行的类型转换**

​		C++11将使用大括号的初始化称为列表初始化（list-initialization）。具体来讲，列表初始化不允许缩窄操作，即变量的类型可能无法表示赋给它的值。

**示例：**

```c++
const int code = 66;
int x = 66;
char c1 = {31325}; // 缩窄操作，不被允许，char 最大是255
char c2 = {66}; // 正确
char c3 {code}; // 正确
char c4 = {x}; // 不被允许，x不是一个常量
x = 31325;
char c5 = x; // 允许，但是执行报错
```

​		从上述 c4 和 c5 的初始化中就可以看出以{ }来初始化时的严格之处，首先必须是个常量才可以将其初始化为 char 类型，而等号赋值在编译阶段不会检查这种错误。



**1.2.3 表达式中的转换**

​		当同一个表达式中包含两种不同的算数类型时，将会出现什么情况？在这种情况下，C++将执行两种自动转换：首先，一些类型在出现时便会自动转换；其次，有些类型在与其他类型同时出现在表达式中时将被转换。下面是C++11版本的校验表，编译器将依次查阅该列表。

​		（1）如果有一个操作数的类型是 long double，则将另一个操作数转换为 long double。

​		（2）否则，如果有一个操作数的类型是 double，则将另一个操作数转换为 double。

​		（3）否则，如果有一个操作数的类型是 float，则将另一个操作数转换为 float。

​		（4）否则，说明操作数都是整型，因此执行整型提升。

​		（5）在这种情况下，如果两个操作数都是有符号或无符号的，且其中一个操作数的级别比另一个低，则转换为级别高的类型。

​		（6）如果一个操作数为有符号的，另一个操作数为无符号的，且无符号操作数的级别比有符号操作数高，则将有符号操作数转换为无符号操作数所属的类型。

​		（7）否则，如果有符号类型可表示无符号类型的所有可能取值，则将无符号操作数转换为有符号操作数所属的类型。

​		（8）否则，将两个操作数都转换为有符号类型的无符号版本。



**1.2.4 传递参数时的转换**

​		C++将对 char 和 short 类型（signed 和 unsigned）应用整型提升。此外，为了保持与传统 C 语言中大量代码的兼容性，将在参数传递给取消原型对参数传递控制的函数时，C++将 float 参数提升为 double。



**1.2.5 强制类型转换**

​		C++还允许通过强制类型转换机制显式地进行类型转换。强制类型转换的格式有两种。例如，为将存储在变量 thorn 中的 int 值转换为 long 类型，可以使用下述表达式的一种：

```c++
int thorn = 1;
(long) thorn;  // return a type long conversion of thorn
long (thorn);  // return a type long conversion of thorn
```

​		此外，C++还引入了4个强制类型转换运算符，对它们的使用要求更为严格。

​		（1）static_cast<> 

​		可以将值从一种数值类型转换为另一种数值类型。

```c++
static_cast<long> (thorn); // return a type long conversion of thorn

// 通用范例
static_cast<typename> (value) 
```

​		（2）dynamic_cast<>

【还没写呢】

​		（3）const_cast<>

​		const_cast<>运算符用于执行只有一种用途的类型转换，即改变值为 const 或 volatile，其语法与dynamic_cast<>运算符相同。

```c++
const_cast <type-name> (expression)
```

​		如果类型的其他方面被修改，则上述类型转换将出错。也就是说，除了 const 或 volatile 特征（有或无）可以不同外，type-name 和 expression 的类型必须相同。假设 High 和 Low 是两个类：

```c++
High bar;
const High* pbar = &bar;
High* pb = const_cast<High*> (pbar); // valid
const Low* pl = const_cast<const Low*> (pbar); // invalid
```

​		第一个类型转换使得 *pb 成为一个可用于修改 bar 对象值的指针，它删除 const 标签。第二个类型转换是非法的，因为它同时尝试将类型从 const High 改为 const Low。

​		提供这种运算符的原因是，有时候可能需要这样一个值，他在大多数的时候是常量，而有时又是可以修改的。在这种情况下，可以将这个值声明为 const，并在需要修改它的值的时候，使用 const_cast<>来实现。

​		（4）reinterpret_cast<>

​		reinterpret_cast<> 运算符用于天生危险的类型转换。它不允许删除 const，但会执行其他令人生厌的操作。有时程序员必须做一些依赖于实现的、令人生厌的操作，使用 reinterpret_cast<>运算符可以简化对这种行为的跟踪工作。

```c++
reinterpret_cast <type-name> (expression);

// 下面是一个使用示例
struct dat {short a; short b;};
long value = 0xA224B118;
dat* pd = reinterpret_cast <dat*> (&value);
cout<< hex << pa->a; // display first 2 bytes of value
```



### 1.3 static



### 1.4 auto、decltype

auto在 C++11 里最多的使用场景就是作为自动类型推导符号

这里将举例 auto 和 decltype 的组合使用

当我们在写函数模板时，如果函数需要返回值，这是我们是无法确定应该返回的类型是什么的，这时候就可以采用下面这种写法：

```c++
template<class T1, class T2>
auto gt(T1 x, T2 y) -> decltype (x+y)
{
    ...
    return x+y;
}
```







## 2 复合类型

本节主要讨论以下几个方面的内容

- **枚举类型**
- **指针、数组和指针算术**
- 栈区：由编译器自动分配释放, 存放函数的参数值,局部变量等
- 堆区：由程序员分配和释放,若程序员不释放,程序结束时由操作系统回收

### 2.1 枚举类型

**作用： **给变量起别名

**语法：** `数据类型 &别名 = 原名`



**示例：**

```C++
int main() {

	int a = 10;
	int &b = a;

	cout << "a = " << a << endl;
	cout << "b = " << b << endl;

	b = 100;

	cout << "a = " << a << endl;
	cout << "b = " << b << endl;

	system("pause");

	return 0;
}
```







### 2.2 指针、数组和指针算数

* 引用必须初始化
* 引用在初始化后，不可以改变

示例：

```C++
int main() {

	int a = 10;
	int b = 20;
	//int &c; //错误，引用必须初始化
	int &c = a; //一旦初始化后，就不可以更改
	c = b; //这是赋值操作，不是更改引用

	cout << "a = " << a << endl;
	cout << "b = " << b << endl;
	cout << "c = " << c << endl;

	system("pause");

	return 0;
}
```











### 2.3 引用做函数参数

**作用：**函数传参时，可以利用引用的技术让形参修饰实参

**优点：**可以简化指针修改实参



**示例：**

```C++
//1. 值传递
void mySwap01(int a, int b) {
	int temp = a;
	a = b;
	b = temp;
}

//2. 地址传递
void mySwap02(int* a, int* b) {
	int temp = *a;
	*a = *b;
	*b = temp;
}

//3. 引用传递
void mySwap03(int& a, int& b) {
	int temp = a;
	a = b;
	b = temp;
}

int main() {

	int a = 10;
	int b = 20;

	mySwap01(a, b);
	cout << "a:" << a << " b:" << b << endl;

	mySwap02(&a, &b);
	cout << "a:" << a << " b:" << b << endl;

	mySwap03(a, b);
	cout << "a:" << a << " b:" << b << endl;

	system("pause");

	return 0;
}

```



> 总结：通过引用参数产生的效果同按地址传递是一样的。引用的语法更清楚简单













### 2.4 引用做函数返回值



作用：引用是可以作为函数的返回值存在的



注意：**不要返回局部变量引用**

用法：函数调用作为左值



**示例：**

```C++
//返回局部变量引用
int& test01() {
	int a = 10; //局部变量
	return a;
}

//返回静态变量引用
int& test02() {
	static int a = 20;
	return a;
}

int main() {

	//不能返回局部变量的引用
	int& ref = test01();
	cout << "ref = " << ref << endl;
	cout << "ref = " << ref << endl;

	//如果函数做左值，那么必须返回引用
	int& ref2 = test02();
	cout << "ref2 = " << ref2 << endl;
	cout << "ref2 = " << ref2 << endl;

	test02() = 1000;

	cout << "ref2 = " << ref2 << endl;
	cout << "ref2 = " << ref2 << endl;

	system("pause");

	return 0;
}
```





​	









### 2.5 引用的本质

本质：**引用的本质在c++内部实现是一个指针常量.**

讲解示例：

```C++
//发现是引用，转换为 int* const ref = &a;
void func(int& ref){
	ref = 100; // ref是引用，转换为*ref = 100
}
int main(){
	int a = 10;
    
    //自动转换为 int* const ref = &a; 指针常量是指针指向不可改，也说明为什么引用不可更改
	int& ref = a; 
	ref = 20; //内部发现ref是引用，自动帮我们转换为: *ref = 20;
    
	cout << "a:" << a << endl;
	cout << "ref:" << ref << endl;
    
	func(a);
	return 0;
}
```

结论：C++推荐用引用技术，因为语法方便，引用本质是指针常量，但是所有的指针操作编译器都帮我们做了













### 2.6 常量引用



**作用：**常量引用主要用来修饰形参，防止误操作



在函数形参列表中，可以加==const修饰形参==，防止形参改变实参



**示例：**



```C++
//引用使用的场景，通常用来修饰形参
void showValue(const int& v) {
	//v += 10;
	cout << v << endl;
}

int main() {

	//int& ref = 10;  引用本身需要一个合法的内存空间，因此这行错误
	//加入const就可以了，编译器优化代码，int temp = 10; const int& ref = temp;
	const int& ref = 10;

	//ref = 100;  //加入const后不可以修改变量
	cout << ref << endl;

	//函数中利用常量引用防止误操作修改实参
	int a = 10;
	showValue(a);

	system("pause");

	return 0;
}
```









## 3 智能指针

如果在程序中使用 new 从堆分配内存，等到不再需要时，应使用 delete 将其释放。C++ 引入了智能指针 auto_ptr，以帮助自动完成这个过程。随后的编程体验（尤其是使用 STL 时）表明，需要有更精致的机制。基于程序员的编程体验和 BOOST 库提供的解决方案， C++11 摒弃了 auto_ptr，并新增了三种智能指针：unique_ptr，shared_ptr 和 weak_ptr。

所有新增的智能指针都能与 STL 容器和移动语义协同工作。



### 3.1 什么是智能指针？

请看下面一段代码：

```c++
void remodel(string &str)
{
    string *ps = new string(str);
    // ...
    str = *ps;
    return;
}
```

上述代码有个很显然的错误，就是我在堆区创建了一个字符串，但在函数结束时并没有做回收，这会导致很严重的内存泄漏问题。

设想如果 ps 有一个析构函数，该析构函数将在 ps 过期时释放它指向的内存。而 ps 存在的问题就是它只是一个常规的指针，不会自动析构。

而这种自动析构技术，就是unique_ptr，shared_ptr，weak_ptr 背后的思想。

为了使用智能指针，首先引入头文件 memory ，下面是对 remodel() 函数使用 auto_ptr 的改写：

```c++
#include <memory>
void remodel(string &str)
{
    auto_ptr<string> ps (new string(str));
    // ...
    str = *ps;
    return;
}
```



所有的智能指针类都有一个 explicit 构造函数，该构造函数将指针作为参数。因此，不会自动将指针转换成智能指针对象：

```c++
shared_ptr<double> pd;
double *p_reg = new double;
pd = p_reg;                         // invalid
pd = shared_ptr<double>(p_reg);     // valid
shared_ptr<double> pshared = p_reg; // invalid
shared_ptr<double> pshared(p_reg);  // valid
```



需要强调一点，对于全部三种智能指针应该避免下列情况：

```c++
string vacation("I wanted lonely as a cloud.");
shared_ptr<string> pvac(&vacation);  // invalid!!!
```

**智能指针只能指向堆区数据！**



### 3.2 unique_ptr

重点探讨 auto_ptr 和 unique_ptr 的不同。



1. **unique_ptr 更安全**

请看下面的一段语句

```c++
auto_ptr<string> p1(new string("hello"));
auto_ptr<string> p2;
p2 = p1;  // *p2 = "hello"，p1 = NULL
```

这三行代码在编译阶段是不会出错的，也就是说 auto_ptr 允许以赋值的方式转让所有权，这是一件好事，防止 p1 和 p2 的析构函数试图删除同一个对象；但程序如果随后试图使用 P1，这将是一件坏事，会产生未定义的行为。

而对于 unique_ptr 而言，其不允许赋值语句的出现，即下面的代码是非法的：

```c++
unique_ptr<string> p1(new string("hello"));
unique_ptr<string> p2;
p2 = p1;  // invalid
```

编译器认为第三句是非法的，避免了 p1 不再指向有效数据的问题。因此 unique_ptr 相比于 auto_ptr 更安全。



**程序试图将一个 unique_ptr 赋给另一个时，如果源 unique_ptr 是一个临时右值，编译器允许这样操作，即临时对象**

**如果源 unique_ptr 将存在一段时间，编译器将禁止这样做！**

```c++
using namespace std;
unique_ptr<string> pu1(new string("Hi Yo!"));
unique_ptr<string> pu2;
pu2 = pu1;                                      // invalid
pu2 = move(pu1);                                // valid
unique_ptr<string> pu3;
pu3 = unique_ptr<string> (new string("Yo!"));   // valid
```

如果想要实现类似于 pu2 = pu1 的操作，可以使用转移语义来实现。

2. **unique_ptr 可用于数组**

在堆区创建数据时，必须使用 new - delete 和 new[] - delete[] 配对使用，但是 auto_ptr 仅支持 new - delete的实现，unique_ptr 支持了对数组版本的实现，值得一提的是，它也是唯一一个支持 new[] - delete[] 的

```c++
unique_ptr<double[]> pda(new double(5));
```



**示例：不能直接通过值给函数传递一个智能指针，因为通过值传递将导致复制真正的形参。如果要让函数通过值接收一个独占指针，则在调用函数时，必须对真正的形参使用 move() 函数：**

```c++
//函数使用通过值传递的形参
void fun(unique_ptr<int> uptrParam)
{
    cout << *uptrParam << endl;
}
int main()
{
    unique_ptr<int> uptr(new int);
    *uptr = 10;
    fun (move (uptr)); // 在调用中使用 move
}
```



**示例：如果通过引用传递的方式，那就不必对真正的形参使用 move() 函数了：**

```c++
//函数使用通过引用传递的值
void fun(unique_ptr<int>& uptrParam)
{
    cout << *uptrParam << endl;
}
int main()
{
    unique_ptr<int> uptr(new int);
    *uptr1 = 15;
    fun (uptr1) ; //在调用中无须使用move
}
```



**示例：可以从函数中返回一个独占指针，因为在遇到返回 unique_ptr 对象的函数时，编译器会自动应用 move() 操作以返回其值**

```c++
//返回指向动态分配资源的独占指针
unique_ptr<int> makeResource()
{
    unique_ptr<int> uptrResult(new int);
    *uptrResult = 55;
    return uptrResult;
}
int main()
{
    unique_ptr<int> uptr;
    uptr = makeResource () ; // 自动移动
    cout << *uptr << endl;
}
```



### 3.3 shared_ptr

在此介绍一个所有权（ownership）的概念，对于特定的对象，对于 unique_ptr 和 auto_ptr 来说，只能有一个智能指针可以拥有它，在类模板内部对 = 运算符进行了重载，让赋值操作转让所有权。

```c++
auto_ptr<int> p1 (new int(1));
unique_ptr<int> p2 = p1;   // p1 is NULL, *p2 = 1，只是为了理解unique_ptr的移动语义，但实际上这句是违法的
```

创建智能更高的指针，跟踪引用特定对象的智能指针数。这被称为引用计数（reference counting）。例如，赋值时，计数将加一，而指针过期时，计数将减一。仅当最后一个指针过期时，才调用 delete，这是 shared_ptr 采用的策略

```c++
unique_ptr<int> p1 (new int(1));
shared_ptr<int> p2 = p1;   // *p1 = *p2 = 1;
```





### 3.4 如何选择智能指针

如果一个程序要使用多个指向同一个对象的指针，应该选择 shared_ptr。这样情况有包括：有一个指针数组，并使用一些辅助指针来标识特定的元素，如最大的元素和最小的元素；两个对象包含都指向第三个对象的指针；包含指针的 STL 容器。很多 STL 算法都支持复制和赋值操作，这些操作可用于 shared_ptr，但不能用 unique_ptr（编译器发出警报）和 auto_ptr（行为不确定）。

如果程序不需要多个指向同一个对象的指针，则可使用 unique_ptr。如果函数使用 new 来分配内存，并返回指向该内存的指针，将其返回类型声明称 unique_ptr 是不错的选择。



### 3.5 weak_ptr

C++11标准虽然将 weak_ptr 定位为智能指针的一种，但该类型指针通常不单独使用（没有实际用处），只能和 shared_ptr 类型指针搭配使用。甚至于，我们可以将 weak_ptr 类型指针视为 shared_ptr 指针的一种辅助工具，借助 weak_ptr 类型指针， 我们可以获取 shared_ptr 指针的一些状态信息，比如有多少指向相同的 shared_ptr 指针、shared_ptr 指针指向的堆内存是否已经被释放等等。

需要注意的是，当 weak_ptr 类型指针的指向和某一 shared_ptr 指针相同时，weak_ptr 指针并不会使所指堆内存的引用计数加 1；同样，当 weak_ptr 指针被释放时，之前所指堆内存的引用计数也不会因此而减 1。也就是说，weak_ptr 类型指针并不会影响所指堆内存空间的引用计数。

weak_ptr 指针更常用于指向某一 shared_ptr 指针拥有的堆内存，因为在构建 weak_ptr 指针对象时，可以利用已有的 shared_ptr 指针为其初始化。例如：

```c++
shared_ptr<int> sp(new int);
weak_ptr<int> wp(sp);
```



**示例：weak_ptr 部分成员方法的基本用法**

```c++
int main()
{
	shared_ptr<int> sp1(new int(10));
	shared_ptr<int> sp2(sp1);
	weak_ptr<int> wp(sp2);

	// 输出和 wp 同指向的 shared_ptr 类型指针的数量
	cout << wp.use_count() << endl;

	// 释放 sp2
	sp2.reset();
	cout << wp.use_count() << endl;

	// 借助 lock() 函数，返回一个和 wp 同指向的 shared_ptr 类型指针，获取其存储的数据
	cout << *(wp.lock()) << endl;

	system("pause");
	return 0;
}
```









## **4** 内存模型

### 4.1 存储连续性

C++11 采用四种不同的方案来存储数据，这些方案的区别就在于数据保留在内存中的时间：

1. 自动存储连续性：在函数定义中声明的变量（包括函数参数）的存储连续性为自动的。它们在程序开始执行其所属的函数或代码块时被创建，在执行完函数或代码块时，它们使用的内存被释放。C++ 有两种存储持续性为自动的变量。
2. 静态存储连续性：在函数定义外定义的变量和使用关键字 static 定义的变量的存储连续性都为静态。它们在程序整个运行过程中都存在。C++ 有三种存储持续性为静态的变量。
3. 线程存储连续性：当前，多核处理器很常见，这些 CPU 可同时处理多个执行任务。这让程序能够将计算放在可并行处理的不同线程中。如果变量是使用关键字 thread_local 声明的，则其生命周期与所属的线程一样长。
4. 动态存储连续性：用 new 运算符分配的内存将一直存在，直到使用 delete 运算符将其释放或程序结束。



### 4.2 自动存储连续性

**在默认情况下，在函数中声明的函数参数和变量的存储连续性为自动，作用域为局部，没有链接性。**



### 4.3 静态持续变量

和 C 语言一样，C++ 也为静态存储持续变量提供了三种链接性：外部链接性（可在其他文件中访问）、内部链接性（只能在当前文件访问）、无链接性（只能在当前函数或代码块中访问）。

由于静态变量的数目在程序运行期间是不变的，因此程序不需要用特殊的内存来管理它们，编译器将分配固定的内存块来存储所有的静态变量。

下面介绍如何创建这三种静态变量：

```c++
// ...
int global = 1000;        // 在代码块外部声明，不加 static，具有外部链接性
static int one_file = 50; // 在代码块外部声明，加 static，具有内部链接性

int main()
{
    //...
}

void func1(int n)
{
    static int cnt = 0;   // 在函数体或者代码块内部声明，加 static，无链接性
}
```



#### 4.3.1 外部链接性

如果要在多个文件中使用外部变量，只需要在一个文件中包含该变量的定义（单定义规则），但在使用该变量的其他所有文件中，都必须使用关键字 extern 声明它：

```c++
// file01.cpp
int cats = 20;
int dogs = 10;

// file02.cpp
extern int cats;
extern int dogs;
```



#### 4.3.2 内部链接性

变量作用域为该文件内部，使用 static 用于区分外部链接性的变量，此使是可以重名的。编译器会隐藏重名的外部链接性变量。

```c++
// file01.cpp
int cats = 20;
int dogs = 10;

// file02.cpp
extern int cats;
static int dogs = 20; // valid
```



#### 4.3.3 无链接性

一般用于在函数体内部定义无链接性的静态变量，这意味着虽然该变量只在该代码块中可用，但它在该代码块不处于活动状态时仍然存在。

因此在两次函数调用之间，静态局部变量的值将保持不变。

如果初始化了静态局部变量，则程序只在启动时进行一次初始化，以后再调用函数时，将不会像自动变量那样再次被初始化。





### 4.4 说明符和限定符

有些被称为存储说明符（storage class specifier）或 cv-限定符（cv-qualifier）的C++ 关键字提供了其他有关内存的信息。下面是存储说明符：

| register         | 显式地指出变量是自动的                       |
| ---------------- | -------------------------------------------- |
| **static**       | **定义了三种链接性的静态变量**               |
| **extern**       | **声明引用在其他文件定义的变量**             |
| **thread_local** | **指出变量的持续性与其所属线程的持续性相同** |
| **mutable**      | **可以修改由const限定的变量**                |



下面是cv-限定符：

| const        | const定义的变量是内部链接性的                                |
| ------------ | ------------------------------------------------------------ |
| **volatile** | **即使程序代码没有对内存单元进行修改，其值也可能发生变化（用于一些硬件数据）** |



#### **4.4.1 mutable**

mutable 可以用来指出，即使结构（类）变量为 const，其某个成员也可以被修改。例如，请看下例：

```c++
struct data
{
    char name[30];
    mutable int accesses;
};

const data veep = {"Claybourne",0};
strcpy(veep.name, "Joye Joux");   // invalid
veep.accesses++;                  // valid
```

veep 的 const 限定符禁止程序修改 veep 的成员，但 accesses 成员的 mutable 说明符使得 accesses 不受这种限制。




### 4.5 函数和链接性

C++不允许在一个函数中定义另一个函数，因此所有函数的存储持续性都自动为静态的。

可以使用 static 关键字将函数的链接性设置为内部的，使之只能在一个文件中使用。

```c++
static int private(double x);

static int private(double x)
{
    ...
}
```





## 5 文件操作



程序运行时产生的数据都属于临时数据，程序一旦运行结束都会被释放

通过**文件可以将数据持久化**

C++中对文件操作需要包含头文件 ==&lt; fstream &gt;==



文件类型分为两种：

1. **文本文件**     -  文件以文本的**ASCII码**形式存储在计算机中
2. **二进制文件** -  文件以文本的**二进制**形式存储在计算机中，用户一般不能直接读懂它们



操作文件的三大类:

1. ofstream：写操作
2. ifstream： 读操作
3. fstream ： 读写操作



### 5.1文本文件

#### 5.1.1写文件

   写文件步骤如下：

1. 包含头文件   

     \#include <fstream\>

2. 创建流对象  

   ofstream ofs;

3. 打开文件

   ofs.open("文件路径",打开方式);

4. 写数据

   ofs << "写入的数据";

5. 关闭文件

   ofs.close();

   

文件打开方式：

| 打开方式    | 解释                       |
| ----------- | -------------------------- |
| ios::in     | 为读文件而打开文件         |
| ios::out    | 为写文件而打开文件         |
| ios::ate    | 初始位置：文件尾           |
| ios::app    | 追加方式写文件             |
| ios::trunc  | 如果文件存在先删除，再创建 |
| ios::binary | 二进制方式                 |

**注意：** 文件打开方式可以配合使用，利用|操作符

**例如：**用二进制方式写文件 `ios::binary |  ios:: out`





**示例：**

```C++
#include <fstream>

void test01()
{
	ofstream ofs;
	ofs.open("test.txt", ios::out);

	ofs << "姓名：张三" << endl;
	ofs << "性别：男" << endl;
	ofs << "年龄：18" << endl;

	ofs.close();
}

int main() {

	test01();

	system("pause");

	return 0;
}
```

总结：

* 文件操作必须包含头文件 fstream
* 读文件可以利用 ofstream  ，或者fstream类
* 打开文件时候需要指定操作文件的路径，以及打开方式
* 利用<<可以向文件中写数据
* 操作完毕，要关闭文件

















#### 5.1.2读文件



读文件与写文件步骤相似，但是读取方式相对于比较多



读文件步骤如下：

1. 包含头文件   

     \#include <fstream\>

2. 创建流对象  

   ifstream ifs;

3. 打开文件并判断文件是否打开成功

   ifs.open("文件路径",打开方式);

4. 读数据

   四种方式读取

5. 关闭文件

   ifs.close();



**示例：**

```C++
#include <fstream>
#include <string>
void test01()
{
	ifstream ifs;
	ifs.open("test.txt", ios::in);

	if (!ifs.is_open())
	{
		cout << "文件打开失败" << endl;
		return;
	}

	//第一种方式
	//char buf[1024] = { 0 };
	//while (ifs >> buf)
	//{
	//	cout << buf << endl;
	//}

	//第二种
	//char buf[1024] = { 0 };
	//while (ifs.getline(buf,sizeof(buf)))
	//{
	//	cout << buf << endl;
	//}

	//第三种
	//string buf;
	//while (getline(ifs, buf))
	//{
	//	cout << buf << endl;
	//}

	char c;
	while ((c = ifs.get()) != EOF)
	{
		cout << c;
	}

	ifs.close();


}

int main() {

	test01();

	system("pause");

	return 0;
}
```

总结：

- 读文件可以利用 ifstream  ，或者fstream类
- 利用is_open函数可以判断文件是否打开成功
- close 关闭文件 















### 5.2 二进制文件

以二进制的方式对文件进行读写操作

打开方式要指定为 ==ios::binary==



#### 5.2.1 写文件

二进制方式写文件主要利用流对象调用成员函数write

函数原型 ：`ostream& write(const char * buffer,int len);`

参数解释：字符指针buffer指向内存中一段存储空间。len是读写的字节数



**示例：**

```C++
#include <fstream>
#include <string>

class Person
{
public:
	char m_Name[64];
	int m_Age;
};

//二进制文件  写文件
void test01()
{
	//1、包含头文件

	//2、创建输出流对象
	ofstream ofs("person.txt", ios::out | ios::binary);
	
	//3、打开文件
	//ofs.open("person.txt", ios::out | ios::binary);

	Person p = {"张三"  , 18};

	//4、写文件
	ofs.write((const char *)&p, sizeof(p));

	//5、关闭文件
	ofs.close();
}

int main() {

	test01();

	system("pause");

	return 0;
}
```

总结：

* 文件输出流对象 可以通过write函数，以二进制方式写数据











#### 5.2.2 读文件

二进制方式读文件主要利用流对象调用成员函数read

函数原型：`istream& read(char *buffer,int len);`

参数解释：字符指针buffer指向内存中一段存储空间。len是读写的字节数

示例：

```C++
#include <fstream>
#include <string>

class Person
{
public:
	char m_Name[64];
	int m_Age;
};

void test01()
{
	ifstream ifs("person.txt", ios::in | ios::binary);
	if (!ifs.is_open())
	{
		cout << "文件打开失败" << endl;
	}

	Person p;
	ifs.read((char *)&p, sizeof(p));

	cout << "姓名： " << p.m_Name << " 年龄： " << p.m_Age << endl;
}

int main() {

	test01();

	system("pause");

	return 0;
}
```



- 文件输入流对象 可以通过read函数，以二进制方式读数据

