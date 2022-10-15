# C++多线程

本阶段主要针对C++多线程编程的笔记。



## 1 基本概念



### 1.1 并发、线程、进程

**1.1.1 并发**

两个或者更多的任务（独立的活动）同时发生；一个程序同时执行多个独立的任务；

单核CPU，某个时刻只能执行一个任务：实现并发的方式是由操作系统调度，在单位时间内进行所谓的“任务切换”；

这种不是真正意义上的并发，这种切换（上下文切换）是要有时间开销的（保存切换前的局部变量和进度便于恢复）；

多核CPU就可以实现真正意义上的并发 （硬件并发）。



**1.1.2 进程**

一个可执行文件运行起来了，就叫创建了一个进程。



**1.1.3 线程**

每个进程（执行起来的可执行程序），都有一个主线程，这个主线程是唯一的，也就是说一个进程中只能有一个主线程。

当执行一个可执行文件，产生了一个进程之后，这个主线程就随着这个进程执行起来了。

使用 ctrl+f5 运行程序时，实际上是进程的主线程来执行 main 函数中的代码。

主线程和进程唇齿相依，主线程就是来执行 main() 函数。

线程： 就是用来执行代码的，理解成一条代码的执行通路。

 除了主线程之外，我们可以通过自己写代码来创建其他线程。

每创建一个新线程，就可以在同一时刻多干一件事（多走一条不同的代码执行路径）。



多线程（并发）：

线程并不是越多越好，每个线程都需要一个独立的堆栈空间（1M左右），线程切换之间需要保存很多中间状态。

切换会耗费本该属于程序运行的时间。



**1.1.4 总结**

（1）线程是用来执行代码的；

（2）把线程这个东西理解成一条代码的执行通路，一个新线程代表一个新的通路；

（3）一个进程自动包括一个主线程，我们可以通过编码来创建多个其他线程（非主线程）；

（4）由于内存和上下文切换带来的开销，线程的数量不要超过200-300个；

（5）由于主线程是跟随进程自动启动的，所以一个进程中至少也会有一个线程（主线程）；

（6）说白了，多线程程序就是可以同时干多个事儿，所以运行效率高，但是到底有多高并不是一件容易量化的事儿；




### 1.2 并发的实现方法

实现并发的手段包括：通过多个进程实现并发，在单独的进程中创建多个线程实现并发。



**1.2.1 多进程并发**

在任务管理器中可以看到，比如：账号服务器，游戏逻辑服务器之间的并发与通信。

实现进程之间的通信：

同一台电脑上：管道、文件、消息队列、共享内存

不同电脑上：socket通信技术



**1.2.2 多线程并发**
在单个进程中创建了多个线程，感觉像是轻量级的进程，每个线程都有自己独立的运行路径

一个进程中所有线程共享地址空间（共享内存），全局变量，指针，引用等都可以在线程之间传递

使用多线程开销远远小于多进程

共享内存带来的新问题：**数据一致性问题**；

多进程并发和多线程并发虽然可以混合使用，但建议优先考虑多线程技术，后续的并发都是多线程并发。



**1.2.3 总结**

和进程相比，线程有如下优点：

（1）线程启动速度更快，更轻量级；

（2）系统资源开销更少，执行速度更快，比如共享内存这种通信方式比其他任何通信方式都快。

但也存在着一定的缺点：

使用有一定难度，要小心处理数据一致性问题。



### 1.3 C++11新标准线程库

以往，不同的操作系统使用不同的方法创建线程

 windows： CreateThread(), _beginthread(), _beginthreadexe() 创建线程

linux： pthread_create() 创建线程

临界区，互斥量

以往多线程代码不能跨平台

存在跨平台的配置库 POSIX thread(pthread) 用起来也不是特别方便

从c++11新标准，c++语言本身增加对多线程的支持，意味着可移植性（跨平台）。



## 2 thread类

### 2.1 范例演示线程的开始和结束

可执行程序运行起来生成一个进程，同时该进程所属的主线程开始自动运行

主线程从 main() 函数开始执行，那么我们自己创建的线程，也需要从一个函数开始运行（初始函数）

整个进程是否执行完毕的标志是：主线程是否执行完毕

此时，一般情况下，如果其他子线程还没有执行完毕，那么这些子线程也会被操作系统强行终止

所以，如果想保持子线程的运行状态，那么要保证主线程一直运行【有例外】



编写多线程函数的基本操作：

（1）包含头文件 thread ， thread 是标准库中的一个类

（2）创建初始函数（线程入口函数）

（3）在 main() 函数中编写代码



### 2.2 .join()方法

阻塞主线程，保证主线程等待子线程执行完毕，主线程最后退出



**示例：**

```C++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

// 子线程入口函数
void myprint()
{
	cout << "子线程开始执行..." << endl;
	cout << "子线程id= " << std::this_thread::get_id() << endl;
	// ...
	cout << "子线程执行完毕 1" << endl;
	cout << "子线程执行完毕 2" << endl;
	cout << "子线程执行完毕 3" << endl;
	cout << "子线程执行完毕 4" << endl;
	cout << "子线程执行完毕 5" << endl;
}


int main()
{
	cout << "主线程开始执行..." << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	std::thread t1(myprint); // 创建一个线程，函数做线程参数
	t1.join();
	cout << "主线程执行完毕" << endl;

	system("pause");
	return 0;
}

/*
输出：
	主线程开始执行...
	主线程id= 16288
	子线程开始执行...
	子线程id= 16196
	子线程执行完毕 1
	子线程执行完毕 2
	子线程执行完毕 3
	子线程执行完毕 4
	子线程执行完毕 5
	主线程执行完毕
	请按任意键继续. . .
*/
```



### 2.3 .detach()方法

 .detach() 分离，也就是主线程不和子线程汇合了，各走各的，主线程不必等子线程了。

为什么引入detach()？我们创建很多子线程，让主线程逐个等待子线程结束，这种编程方法不太好，所以引入detach()

一旦detach()之后，与这个主函数关联的thread对象就会失去与主线程的关联，此时这个子线程就会驻留在后台运行。

这个子线程就相当于被c++运行时库接管，当子线程执行结束后，由运行时库负责清理该线程相关资源（守护线程）



**示例：**

```C++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

// 子线程入口函数
void myprint()
{
	cout << "子线程开始执行..." << endl;
	cout << "子线程id= " << std::this_thread::get_id() << endl;
	// ...
	cout << "子线程执行完毕 1" << endl;
	cout << "子线程执行完毕 2" << endl;
	cout << "子线程执行完毕 3" << endl;
	cout << "子线程执行完毕 4" << endl;
	cout << "子线程执行完毕 5" << endl;
}


int main()
{
	cout << "主线程开始执行..." << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	std::thread t1(myprint);
	t1.detach();
	cout << "主线程执行完毕" << endl;

	return 0;
}

/*
输出：
	主线程开始执行...
	主线程id= 11144
	子线程开始执行...主线程执行完毕
	子线程id= 7532
	子线程执行完毕 1
	子线程执行完毕 2
	子线程执行完毕 3

	子线程执行完毕 4
*/

```



### 2.4 joinable()方法

判断是否可以成功使用join()或者detach()， 返回true或者false



**示例：**

```C++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

// 子线程入口函数
void myprint()
{
	cout << "子线程开始执行..." << endl;
	cout << "子线程id= " << std::this_thread::get_id() << endl;
	// ...
	cout << "子线程执行完毕" << endl;
}

int main()
{
	cout << "主线程开始执行..." << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	std::thread t1(myprint);
	if (t1.joinable()) cout << "p1 joinable() is true" << endl;
	else cout << "p1 joinable() is false" << endl;
	t1.join();
	if (t1.joinable()) cout << "p2 joinable() is true" << endl;
	else cout << "p2 joinable() is false" << endl;
	cout << "主线程执行完毕" << endl;

	return 0;
}

/*
输出：
	主线程开始执行...
	主线程id= 4696
	子线程开始执行... p1 joinable() is true

	子线程id= 5744
	子线程执行完毕
	p2 joinable() is false
	主线程执行完毕
*/
```

> 通过 .joinable() 的示例，可以看到p2处返回值为 false，说明对于一个线程只能调用一次 .join() 或者 .detach() 



### 2.5 其他创建线程的方法

**2.5.1 用class创建一个可调用对象**

**示例：**

```C++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

// 用class创建可调用对象
class TA
{
public:
	int m_i;
	TA(int &i) :m_i(i) {
		cout << "TA 的构造函数被执行" << endl;
	}
	TA(const TA &ta) :m_i(ta.m_i) {
		cout << "TA 的拷贝构造函数被执行" << endl;
	}
	~TA() {
		cout << "TA 的析构函数被执行" << endl;
	}

    // 必须重载operator()将其变为可调用对象
	//这个函数就是子线程的入口，相当于子线程的main()函数
	void operator()()
	{
		cout << "子线程开始执行..." << endl;
		cout << "子线程id= " << std::this_thread::get_id() << endl;
		// ...
		cout << "子线程执行完毕" << endl;
	}

};

int main()
{
	cout << "主线程开始执行..." << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	int para = 6;
	TA ta(para);
	std::thread t1(ta);  //这里ta是被复制到线程中去的，调用了拷贝构造函数
	t1.join();
	cout << "主线程执行完毕" << endl;

	return 0;
}

/*
输出：
	主线程开始执行...
	主线程id= 7768
	TA 的构造函数被执行
	TA 的拷贝构造函数被执行
	子线程开始执行...
	子线程id= 16052
	子线程执行完毕
	TA 的析构函数被执行
	主线程执行完毕
	TA 的析构函数被执行
*/
```



我们发现在输出中，TA对线在主线程中被构造了一次，在子线程中被拷贝构造了一次，如果我们想使用同一个 TA 的话，可以使用下面的语句进行修改。**而且在使用临时对象传递类对象时，构造函数与拷贝构造函数都是在主线程完成的，保证安全。**



```c++
// 修改前
std::thread t1(ta);

// 修改后
std::thread t1(std::ref(ta));
```



修改后的代码不会调用拷贝构造函数，而是执行真正意义上的引用，将 ta 传递给子线程。



**2.5.2 用lambda表达式创建线程**

```c++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	auto myLamThread = [] {
		cout << "子线程开始执行" << endl;
		cout << "子线程id= " << std::this_thread::get_id() << endl;
		//...
		cout << "子线程执行完毕" << endl;
	};
	std::thread t1(myLamThread);
	t1.join();
	cout << "主线程执行完毕" << endl;
	return 0;
}
```



**2.5.3 用class的成员函数作为可调用对象**

```c++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <list>
#include <thread>
#include <mutex>

using namespace std;

class A
{
	std::list<int> msgRecvQueue;
	std::mutex m_mutex;
public:
	// 接收命令 写操作
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			m_mutex.lock();
			msgRecvQueue.push_back(i);
			m_mutex.unlock();
			// other codes...
		}
	}

	// 操作命令 读写操作
	void outMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			m_mutex.lock();
			if (!msgRecvQueue.empty())
			{
				int cmd = msgRecvQueue.front();
				msgRecvQueue.pop_front();
				m_mutex.unlock();
				cout << "outMsgRecvQueue() 执行，目前指令为：" << cmd << endl;
			}
			else
			{
				m_mutex.unlock();
				cout << "outMsgRecvQueue() 执行，但目前消息队列为空" << endl;
			}
		}
	}
};

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;

	A a;
    
    // 以class的成员函数做线程入口函数的写法
	std::thread t1(&A::outMsgRecvQueue, std::ref(a));
	std::thread t2(&A::inMsgRecvQueue, std::ref(a));
	t1.join();
	t2.join();
	cout << "主线程执行完毕" << endl;
	return 0;
}
```



### 2.6 临时对象

关于临时对象在线程间传递时的两个说明：

（1）即使我们在子线程入口函数中传递了某个变量的引用，但是实际上该变量并不是真正的引用，而是采用的值传递的方式，所以这保证了即使主线程 detach() 了子线程，子线程中的这个变量仍然是安全的；

（2）不要使用指针类型来传递参数！！！



**关于临时对象的几点事实：**

（1）只要用临时构造的类对象作为函数传递给线程，那么就一定能够在主线程执行完毕之前把线程函数的参数构建出来，从而保证了在使用 .detach() 时，子线程可以正常工作

（2）建议在传递类对象时，全部在创建线程时构建临时对象，然后在线程函数定义时使用引用来接收，否则会多进行一次拷贝构造

（3）建议使用到临时对象的子线程不要 .detach()，而只使用 .join()，这样就不存在因为局部变量失效而导致线程对内存的非法引用



## 3 创建多个线程

### 3.1 创建和等待多个线程

可以使用 vector 容器来创建多个线程，便于集中管理

示例中，创建 10 个线程，线程入口函数统一使用 myprint()



**示例：**

```C++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <thread>

using namespace std;

void myprint(int num)
{
	cout << "线程 " << num << " 开始执行" << endl;
	cout << "线程id = " << std::this_thread::get_id() << endl;
	//...
	cout << "线程 " << num << " 执行结束" << endl;
}

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;
	vector<std::thread> mythreads;
	for (int i = 0; i < 10; ++i)
	{
		// 创建10个线程，并开始执行
		mythreads.push_back(std::thread(myprint, i));
	}
	for (auto iter = mythreads.begin(); iter != mythreads.end(); ++iter)
	{
		// 等待10个线程都返回
		iter->join();
	}
	cout << "主线程执行完毕" << endl;
	return 0;
}
```



执行上述的程序，可以通过结果得到如下几个结论：

（1）多个线程的执行顺序是乱的，和操作系统内部调度机制有关；

（2）主线程等待所有子线程运行结束，最后主线程结束，推荐使用 .join() 写法

（3）利用容器来创建多个线程的手法，看起来像个 thread 数组，这对于管理大量线程很方便



### 3.2 浅谈线程池

**3.2.1 场景设想**

在一个服务器程序中，接收来自客户端的消息，客户端每来一个消息，就创建一个新线程为该客户提供服务

假设这是一个网络游戏服务器，那么同一时间假设有来自客户端的 20w 个消息，那么服务器不可能创建 20w 个线程来提供服务

从系统稳定性问题来考虑：

（1）短时间内创建大量线程是不安全的，偶尔创建一个线程这种代码也是不安全的

（2）当计算资源不足时，创建大量线程是有可能会引发系统崩溃的



**3.2.2 线程池的实现方式**

那一对线程弄到一起，统一管理。这种统一管理调度，循环利用线程的方式，就叫线程池。

在程序启动时，我一次性创建好一定数量的线程，用完的线程不会释放该线程。这种方式会使程序代码更稳定。



### 3.3 线程创建数量谈

开辟线程的数量极限问题，2000个线程基本就是极限，再继续创建线程就会崩溃。

线程创建数量建议：

（1）采用某些技术开发程序时，API 接口提供商会建议你创建线程的数量，那就遵守这些建议，确保程序高效执行

（2）创建线程完成业务时，一个线程等于一条执行通路，要考虑业务有多少同时执行的需求

（3）我直接开 1800 个线程不是更好吗？CPU 调度各个线程的时间片，执行效率并不会高，而会下降

（4）建议创建的线程数不要超过500个，200个比较理想，实践出真知！



### 3.4 手写线程池

线程池的组成主要分为三个部分，这三部分配合工作就可以得到一个完整的线程池：

**1、 任务队列，存储需要处理的任务，由工作的线程来处理这些任务**

- 通过线程池提供的 API 函数，将一个待处理的任务添加到任务队列，或者从任务队列中删除
- 已处理的任务会被从任务队列中删除
- 线程池的使用者，也就是调用线程池函数往任务队列中添加人物的线程就是生产者线程

**2、 工作的线程（任务队列任务的消费者），N个**

- 线程池中维护了一定数量的工作线程，它们的作用是不停的读任务队列，从里边取出任务并处理
- 工作的线程相当于是任务队列中的消费者角色
- 如果任务队列为空，工作的线程将会被阻塞（使用条件变量、信号量阻塞）
- 如果阻塞之后有了新的任务，由生产者将阻塞解除，工作线程开始工作

**3、 管理者线程（不处理任务队列中的任务），1个**

- 它的任务是周期性对任务队列中的任务数量以及处于忙状态的工作线程个数进行检测
- 当任务过多的时候，可以适当的创建一些新的工作线程
- 当任务过少的时候，可以适当的销毁一些工作的线程



## **4** 数据共享问题

### 4.1 数据共享问题分析

（1）只读数据

​		只读数据共享是安全稳定的，没有任何问题

（2）读写数据

​		假设两个线程写，八个线程读，如果没有特别处理程序肯定崩溃

​		最简单的不崩溃写法就是读的时候不能写，写的时候不能读，两个线程不能同时写，八个线程不能同时读

​		但这也就违背了多线程的初衷

最直观的数据共享问题案例就是订火车票，两个人不能同时对一个座位进行写操作，否则会产生冲突。



### 4.2 互斥量 mutex

互斥量是一个类对象，可以理解成一把锁头，多线程尝试用 lock() 成员函数来加锁，同一时刻只有一个线程可以锁定成功，成功的标志就是 lock() 函数返回。如果没有加锁成功，那么流程就会卡在 lock() 这里。

互斥量的使用准则切记一条：只保护需要保护的数据即可，应该在 lock()--unlock() 之间编写尽可能少的代码，以提升多线程效率。



**4.2.1 mutex的基本用法**

需要包含头文件 **mutex**

下面是一个 mutex 的简单使用示例，其中一个线程负责接收数据，另一个线程读取消息队列中的信息并进行处理，两个线程不能同时对消息队列进行读写操作，因此需要引入互斥量来保证同一时刻只有一个线程可以操作消息队列。



**示例**

```c++
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <list>
#include <thread>
#include <mutex>

using namespace std;

class A
{
	std::list<int> msgRecvQueue;
	std::mutex m_mutex;
public:
	// 接收命令 写操作
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			m_mutex.lock();
			msgRecvQueue.push_back(i);
			m_mutex.unlock();
			// other codes...
		}
	}

	// 操作命令 读写操作
	void outMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			m_mutex.lock();
			if (!msgRecvQueue.empty())
			{
				int cmd = msgRecvQueue.front();
				msgRecvQueue.pop_front();
				m_mutex.unlock();
				cout << "outMsgRecvQueue() 执行，目前指令为：" << cmd << endl;
			}
			else
			{
				m_mutex.unlock();
				cout << "outMsgRecvQueue() 执行，但目前消息队列为空" << endl;
			}
		}
	}
};

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;

	A a;
	std::thread t1(&A::outMsgRecvQueue, std::ref(a));
	std::thread t2(&A::inMsgRecvQueue, std::ref(a));
	t1.join();
	t2.join();
	cout << "主线程执行完毕" << endl;
	return 0;
}
```



通过上述代码，可以看到使用 lock() 和 unlock() 几点需要注意的地方

（1）lock() 与 unlock() 必须成对使用，否则其他使用该互斥量的线程将会卡死

（2）只允许 lock() 和 unlock() 一次

（3）当使用条件语句做判断时，必须保证在任何条件触发的情况下 unlock() 都可以触发

（4）lock() 和 unlock() 中间最好只包含对保护数据的处理，不要加入其它代码影响执行速度



上述代码仍然存在一些问题，我们将会在后续的讨论中将这个程序修改为最佳的多线程写法。



### 4.3 lock_guard

为了防止忘记 unlock() ，C++引入了一个叫 std::lock_guard 的类模板，其会自动 unlock()

可以直接取代 lock() 和 unlock() 的成对使用规则，因为其构造函数调用了 mutex::lock()，而析构函数调用了 mutex::unlock()

但需要注意的是，我们必须保证 lock_guard 可以正确析构，所以常规的写法是将需要 lock() 的代码段使用一个 { }括起来，在其中定义构造 lock_guard，当程序执行到大括号结束时，lock_guard 将会自行析构



**示例**

```c++
class A
{
	std::list<int> msgRecvQueue;
	std::mutex m_mutex;
public:
	// 接收命令 写操作
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			{
				std::lock_guard<std::mutex> sbguard(m_mutex);
				msgRecvQueue.push_back(i);
			}
			// other codes...
		}
	}

	// 操作命令 读写操作
	void outMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			std::lock_guard<std::mutex> sbguard(m_mutex);
			if (!msgRecvQueue.empty())
			{
				int cmd = msgRecvQueue.front();
				msgRecvQueue.pop_front();
				cout << "outMsgRecvQueue() 执行，目前指令为：" << cmd << endl;
			}
			else
			{
				cout << "outMsgRecvQueue() 执行，但目前消息队列为空" << endl;
			}
		}
	}
};

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;

	A a;
	std::thread t1(&A::outMsgRecvQueue, std::ref(a));
	std::thread t2(&A::inMsgRecvQueue, std::ref(a));
	t1.join();
	t2.join();
	cout << "主线程执行完毕" << endl;
	return 0;
}
```




### 4.4 死锁

C++中死锁产生的前提是至少有两个互斥量

死锁的一般解决方案：只要保证两个互斥量上锁的顺序一致，就不会死锁

std::lock() 提供了一种解决方案，其一次性锁住两个或以上的互斥量，这就导致了不存在这种因为 lock() 顺序问题而导致的死锁风险

std::lock() 保证了两个互斥量要么都锁住，要么都不锁住，其在处理多个互斥量时才会用到，这里暂时不做代码示例。



### 4.5 unique_lock

std::unique_lock 是一个类模板，使用方法和 std::lock_guard类似

unique_lock 相比于 lock_guard 灵活很多，但是占用内存和效率方面表现不太好，在工作中推荐使用 lock_guard



**4.5.1 unique_lock简单用法**

**示例**

```c++
class A
{
	std::list<int> msgRecvQueue;
	std::mutex m_mutex;
public:
	// 接收命令 写操作
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			{
				std::unique_lock<std::mutex> sbguard(m_mutex);
				msgRecvQueue.push_back(i);
			}
			// other codes...
		}
	}

	// 操作命令 读写操作
	void outMsgRecvQueue()
	{
		int cmd = 0;
		for (int i = 0; i < 100000; ++i)
		{
			bool res = outMsgLULProc(cmd);
			if (res)
			{
				cout << "outMsgRecvQueue()正在执行，取出第一个元素" << cmd << endl;
				// other codes...
			}
			else
			{
				cout << "outMsgRecvQueue()正在执行，但目前消息队列为空" << i << endl;
				// other codes...
			}
		}
	}

		bool outMsgLULProc(int&cmd)
		{
			std::unique_lock<std::mutex> sblock(m_mutex);
	
			std::chrono::milliseconds dura(200); // 1s=1000ms 这是0.2s
			std::this_thread::sleep_for(dura); // 休息一定的时长
	
			if (!msgRecvQueue.empty())
			{
				cmd = msgRecvQueue.front();
				msgRecvQueue.pop_front();
				return true;
			}
			return false;
		}
};

int main()
{
	cout << "主线程开始执行" << endl;
	cout << "主线程id= " << std::this_thread::get_id() << endl;

	A a;
	std::thread t1(&A::outMsgRecvQueue, std::ref(a));
	std::thread t2(&A::inMsgRecvQueue, std::ref(a));
	t1.join();
	t2.join();
	cout << "主线程执行完毕" << endl;
	return 0;
}
```



unique_lock的最基本用法和lock_guard一模一样，都是会自动加锁和解锁，而且要在正确的时间析构unique_lock

值得注意的是，上述代码中引入了线程 sleep 函数，让 outMsgRecvQueue() 函数每隔 0.2s 调用一次，这也是让线程休眠的最常用用法，下面是这段代码的描述

```c++
std::chrono::milliseconds dura(200); // 1s=1000ms 这是0.2s
std::this_thread::sleep_for(dura); // 休息一定的时长
```



**4.5.2 unique_lock第二个参数 **

除了与 lock_guard 的相似用法之外，unique_lock 还可以载入第二个参数，来增加其灵活性。

其第二个参数有如下几种：

（1）std::adopt_lock

​		表示这个互斥量已经被 lock 了，在使用adopt_lock 之前必须把互斥量 lock ，否则将会异常

​		这个标记的效果就是 “假设调用方线程已经拥有了互斥的所有权，已经lock成功了”

​		通知 lock_guard不需要在构造函数中调用std::mutex::lock()了

（2）std::tyr_to_lock

​		尝试使用mutex的lock()去锁定mutex，但如果没有锁定成功，也会立即返回，不会阻塞在那里

​		使用try_to_lock的前提是不能手动去lock()

​		会配合unique_lock::owen_lock()使用，组合成一个if else

（3）std::defer_lock

​		用defer_lock的前提是不能自己手动 lock()

​		defer_lock的意思就是并没有给mutex加锁，初始化了一个没有加锁的mutex



**4.5.3 unique_lock 成员函数**

下面是一些 unique_lock 重要的成员函数

（1）lock()

​		一般配合第二个参数 std::defer_lock 使用

（2）unlock()

​		可能中间会处理一些非共享数据参与的代码，这是我们可以选择unlock()共享数据

```c++
unique_lock::lock();
// 处理共享数据...
unique_lock::unlock();
// 处理非共享数据...
unique_lock::lock()
```

​		为什么会需要 unlock() ？因为 lock() 锁住的代码段越少，程序效率越高

（3）try_lock()

​		尝试给 mutex 加锁，如果拿不到锁，则返回 false，拿到锁就返回 true，不会产生阻塞

（4）release()

​		返回它所管理的mutex对象指针，并释放所有权，也就是说这个unique_lock和mutex不再有关系

​		严格区分release()和unlock()，不要混淆

​		release()返回的是mutex指针类型  mutex*

​		如果原来mutex对象处于加锁，你有责任接管过来并负责解锁



**4.5.4 unique_lock 所有权的传递**

```c++
std::unique_lock<std::mutex> sblock(my_mutex);
```

sblock拥有my_mutex的所有权，sblock可以把自己对my_mutex的所有权转移给其他的unique_lock对象

所以unique_lock对于mutex的所有权属于是  可以转移，但是不能复制的

所有权转移的写法

```c++
std::unique_lock<std::mutex> sblock1(my_mutex);
std::unique_lock<std::mutex> sblock2(std::move(sblock1));
```



## 5 单例设计模式

### 5.1 设计模式概谈

设计模式：代码的一些写法，这些写法跟常规写法不怎么样

特点是程序灵活，维护起来可能很方便，但别人接管和阅读都会很痛苦

用设计模式写出来的代码是很晦涩的，当时流行的《head first》流行书

是老外为了应付特别大的项目时，把项目的开发经验、模块划分经验总结整理成了设计模型（先有开发需求，再有理论总结和整理）

设计模式拿到中国来就不太一样了，拿着程序往设计模式上套，一个小小的项目非要弄几个设计模式上去，本末倒置

设计模式有其独特的优点，要活学活用，不要深陷其中，生搬硬套



### 5.2 单例设计模式

单例设计模式使用频率很高

单例的定义就是：在整个项目中，有某个或者某些特殊的类，属于该类的对象，只允许创建一个

下面提供一种单例类的写法



**示例**

```c++
using namespace std;

std::mutex resource_mutex;

class MyCAS
{
private:
	MyCAS() {}  // 私有化构造函数
private:
	static MyCAS* m_instance;  //静态成员变量
public:
	class CGarRecyle  // 类中套类，用来释放该对象
	{
	public:
		~CGarRecyle()
		{
			if (MyCAS::m_instance)
			{
				delete MyCAS::m_instance;
				MyCAS::m_instance = NULL;
			}
		}
	};

	static MyCAS* GetInstance()
	{
		if (m_instance == NULL) // 双重锁定
		{
			std::unique_lock<std::mutex> mylock(resource_mutex);
			if (m_instance == NULL)
			{
				m_instance = new MyCAS();
				static CGarRecyle cl;
			}
		}
		return m_instance;
	}

	void func() { cout << "test" << endl; }
};

void myprint()
{
	cout << "this thread start ..." << endl;
	cout << "thread id = " << std::this_thread::get_id() << endl;
	MyCAS* p_a = MyCAS::GetInstance();
	p_a->func();
	cout << "this thread end" << endl;
}

MyCAS *MyCAS::m_instance = NULL;

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	MyCAS *p_a = MyCAS::GetInstance(); // 创建一个对象，返回该类对象的指针
	p_a->func();
    // 虽然这两个线程是同一个入口函数，但这就是两个函数
    // 两个线程意味着会有两个流程同时开始执行myprint()这个函数，同时创建单例类
	std::thread t1(myprint);
	std::thread t2(myprint);
	t1.join();
	t2.join();
	cout << "main thread end" << endl;
	return 0;
}
```



在上述代码中，保证只会创建一个 MyCAS* 对象，主线程和两个子线程中的 p_a 地址是一样的，这就是单例设计模式。单例设计模式的实现依赖于上述中的 GetInstance() 函数，其中的双重锁定模式保证了 MyCAS 对象只会被创建一个。

需要我们自己创建的线程（而不是主线程）中创建MyCAS这些个单例类的对象，这种线程可能不止一个，我们可能面临的问题就是 MyCAS::GetInstance() 成员函数会互斥。而解决方案上面已经写清楚了，引入了一个互斥量，并且加锁（注意加锁位置，双重检查）。



### 5.3 call_once()

C++11引入该函数，该函数的第二个参数就是函数名 func()

该函数的功能是：能够保证函数 func() 只被调用一次，其具备互斥量的能力，而且比互斥量更加高效

call_once() 需要与一个标记结合使用，std::once_flag，其实std::once_flag 是一个结构体

call_once() 就是通过 std::once_flag 这个标记来决定对应的函数 func() 是否执行

当call_once() 调用一次 func() 之后，对应的标记 std::once_flag 就会被设置为【已调用】状态

当下一次试图调用 func() 时，由于 once_flag 是【已调用】状态，那么 func() 就不会再次调用了



下面的示例使用 call_once 修改了单例设计模式的写法

**示例**

```c++
using namespace std;

std::once_flag g_flag; // call_once 标记位

class MyCAS
{
private:
	MyCAS() {}  // 私有化构造函数
private:
	static MyCAS* m_instance;  //静态成员变量
private:
    // 把创建对象的函数单独封装，便于 call_once 调用
	static void CreateInstance()
	{
		cout << "CreateInstance() 只被执行了一次" << endl;
		m_instance = new MyCAS();
		static CGarRecyle cl;
	}
public:
	class CGarRecyle  // 类中套类，用来释放该对象
	{
	public:
		~CGarRecyle()
		{
			if (MyCAS::m_instance)
			{
				delete MyCAS::m_instance;
				MyCAS::m_instance = NULL;
			}
		}
	};

	static MyCAS* GetInstance()
	{
		std::call_once(g_flag, CreateInstance);  // 如果两个线程同时执行到这里，其中会有一个线程等待另一个线程执行完毕
                                                 // 就相当于 call_once自动给 CreateInstance() 这个函数加了一把锁
        										 // 然后第二个线程会根据 g_flag 状态来决定是否调用 CreateInstance()
		cout << "std::call_once() 执行完毕" << endl;
		return m_instance;
	}

	void func() { cout << "test" << endl; }
};

void myprint()
{
	cout << "this thread start ..." << endl;
	cout << "thread id = " << std::this_thread::get_id() << endl;
	MyCAS* p_a = MyCAS::GetInstance();
	p_a->func();
	cout << "this thread end" << endl;
}

MyCAS *MyCAS::m_instance = NULL;

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	MyCAS *p_a = MyCAS::GetInstance();
	p_a->func();
	std::thread t1(myprint);
	std::thread t2(myprint);
	t1.join();
	t2.join();
	cout << "main thread end" << endl;
	return 0;
}
```



## 6 条件变量

### 6.1 条件变量引入

假设现在有两个线程：线程 A 和线程 B，其各自读写数据的功能如下：

线程A：等待一个条件满足，处理消息队列的

线程B：专门往消息队列中添加数据的

这两个线程就是前文介绍数据共享问题时所用的案例，之前说过代码仍然不是最优的，还可以优化，那么就可以使用条件变量来优化

条件变量的作用就是：让线程 A 等待一个条件，线程 B 满足了这个条件之后触发线程 A，继续向下执行



### 6.2 condition_variable

std::condition_variable 实际上是一个类，是一个和条件相关的类，说白了就是等待一个条件达成

std::condition_variable 需要与互斥量来配合工作，用的时候我们要生成这个类的对象



**6.2.1 wait()**

wait() 是condition_variable 的一个成员函数，表示用来等一个什么东西

wait() 的第一个参数是一个互斥量，如果第二个参数的返回值是 false，那么 wait() 将**解锁互斥量**并且阻塞到本行

阻塞到什么时候为止呢？阻塞到其他线程调用 notify_one() 成员函数为止

如果 wait() 没有第二个参数，那么就跟第二个参数默认为 false ，仍然要等待 notify_one

【关于 wait() 的总结】

（1）第二个参数返回 true，wait() 返回，程序继续执行

（2）第二个参数 false，程序在 wait() 处卡死，直到另一个程序调用 notify_one()，程序才会继续向下执行



**6.2.2 notify_one()**

在另一个线程中调用，把正在 wait() 的线程唤醒，执行完 notify_one() ，那么 wait() 就会被唤醒



用条件变量改写数据共享问题中的代码，其中最大的问题就是在出队列的线程中反复查询消息队列是否为空，这将会浪费大量的资源。

**示例**

```c++
using namespace std;

class A
{
	std::list<int> msgRecvQueue;
	std::mutex m_mutex;
	std::condition_variable m_cond;  // 声明条件变量
public:
	// 接收命令 写操作
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			cout << "thread id = " << std::this_thread::get_id() << endl;
			{
				std::unique_lock<std::mutex> sbguard(m_mutex);
				msgRecvQueue.push_back(i);
				m_cond.notify_one();
			}
			// other codes...
		}
	}

	// 操作命令 读写操作
	void outMsgRecvQueue()
	{
		int cmd = 0;
		while (true)
		{
			std::unique_lock<std::mutex> sbguard(m_mutex);
			m_cond.wait(sbguard, [this] {   // wait()的第二个参数可以是任何一个可调用对象
				if (!msgRecvQueue.empty())
					return true;
				return false;
			});

			// 流程只要能到达这里，说明锁头一定是锁着的
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			sbguard.unlock();  // 结束对共享数据的读写，提前解锁
			cout << "outMsgRecvQueue() 正在执行，取出命令" << cmd << endl;
			cout << "thread id = " << std::this_thread::get_id() << endl;
			// 对 cmd 的一系列处理命令
		}
	}
};

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	A a;
	std::thread t1(&A::outMsgRecvQueue, &a);
	std::thread t2(&A::inMsgRecvQueue, &a);
	t1.join();
	t2.join();
	cout << "main thread end" << endl;
	return 0;
}
```



**6.2.3 notify_one 唤醒 wait 的说明**

当其他线程用 notify_one() 将本 wait() 从睡眠状态唤醒时，wait() 就要恢复工作了

（1）wait() 不断尝试重新获取互斥量锁头，如果获取不到，该线程还是会卡在 wait() 这里

（2）获取到锁头之后，如果 wait() 有第二个参数，那么就判断第二个参数

​		若第二个参数仍为 false，那么 wait() 将会再次解锁该锁头，进入睡眠等待唤醒

​		若第二个参数为 true，则 wait() 返回，代码流程继续执行（此时锁头是上锁的，保护共享数据）

（3）如果 wait() 没有第二个参数，那么 wait() 唤醒后无条件向下执行。



### 6.3 notify_all

在上面使用 wait() 和 notify_one() 的程序中，可能会出现下列两种情况

（1）当 outMsgRecvQueue()在 wait() 唤醒之后，如果执行一段很长的代码（100ms），那么这时即使另一个线程 notify_one()，也不会起任何作用，只有当一个线程正在 wait() 时，notify_one() 才会起作用

（2）如果运行几遍上面的程序，就会发现存在以下现象：消息队列中可能会积压太多数据而来不及处理，这时候我们可以建立多个线程来处理消息队列的信息，但这时就会产生一个新的问题，这也是为什么要引入 notify_all()

所产生的问题就是：

notify_one()只能唤醒一个线程 ， 对应同一个条件变量.wait()的线程

如果系统内存在多个线程使用同一个条件变量的.wait()，那么notify_one()只能唤醒一个线程，至于具体是哪个，随机

如果两个线程做的是不同的指令，都需要被唤醒，那么notify_all()就可以同时唤醒所有线程

```c++
m_cond.notify_all();
```



### 6.4 虚假唤醒

在 6.2 的程序中，如果书写不规范的话可能出现虚假唤醒的现象

对于 6.2 的程序，虚假唤醒就是当前队列还是空的呢，outmsg 就被唤醒了，这是将会发生程序异常

6.2 代码的 lambda 表达式就是正确解决虚假唤醒问题的方案

```c++
m_cond.wait(sbguard, [this] {   // wait()的第二个参数可以是任何一个可调用对象
	if (!msgRecvQueue.empty())
		return true;
	return false;
});
```

这个 lambda 表达式就像是一个双重检查的方案，当 outmsg 线程被唤醒时，它还要再判断一次队列是否为空。如果队列为空，那么 wait() 将会释放锁头，继续等待下一个 notify 信号；如果队列不为空，那么就可以正常执行下面的语句，读写共享数据了。

在使用条件变量时，要仔细考虑解决虚假唤醒的问题，同时也要考虑即时唤醒 wait() 

解决虚假唤醒时，wait() 中最好要有第二个可调用对象，并且这个可调用对象中要正确判断要处理的共享数据是否存在



## 7 异步任务

### 7.1 async、future

我们可以使用 std::async、std::future 创建后台任务并返回值

std::async是一个函数模板，用来启动一个异步任务，启动起来异步任务后，它返回一个std::future对象，std::future是一个类模板

什么叫启动一个异步任务？就是自动创建一个线程并开始执行对应的线程入口函数

这个std::future对象里面就含有线程入口函数所返回的结果（其实就是线程返回的结果），我们可以通过调用future对象的成员函数.get()来获取结果

有人也称呼std::future提供了一种访问异步操作结果的机制，这个结果可能没办法马上拿到，在不久的将来线程执行完毕时就可以拿到结果

所以就这么理解std::future（对象）会保存一个值，这个值在将来的某个时刻可以拿到

std::future.get()只能调用一次！！！

```c++
class A
{
public:
	int myprint(int mypara)  // 线程入口函数
	{
		cout << "myprint() start" << endl;
		cout << mypara << endl;
		cout << "thread id = " << std::this_thread::get_id() << endl;
		std::chrono::milliseconds dura(5000);
		std::this_thread::sleep_for(dura);
		cout << "myprint() end" << endl;
		return 5;
	}
};

void mythread(std::future<int>&tmp)  // 注意参数的写法
{
	cout << "mythread() start" << endl;
	cout << "thread id = " << std::this_thread::get_id() << endl;
	auto res = tmp.get();
	cout << res << endl;
	cout << "mythread() end" << endl;
}

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	A a;
	int para = 12;
	// 使用std::async 创建一个线程并开始执行，用 std::future 来接收返回值
	std::future<int> res = std::async(&A::myprint, &a, para);
	std::thread t2(mythread, std::ref(res));
	t2.join();
	cout << "main thread end" << endl;
	return 0;
}
```



我们可以通过额外向std::async()传递一个参数，该参数类型是std::launch类型，一种枚举类型，来实现一些特殊的用法

（1）std::launch::deferred  

​		延迟创建线程，表示线程入口函数的调用要等到 std::future 的 wait() 和 get() 才会执行

​		如果wait() 和 get 没有被调用，那么线程会执行吗？答案是不会执行，实际上根本没有创建线程

​		实际上在使用 std::launch::deferred 之后，不会创建一个子线程，而是在主线程中调用线程入口函数

（2）std::launch::async

​		与 deferred 不同的是，其不需要 get() 或者 wait() 来启动线程入口函数

```c++
std::future<int> res = std::async(std::launch::deferred, &A::mythread, &a, para);
```



### 7.2 async

async 是用来创建一个异步任务的

在 7.1 中简单介绍了 async 的两个参数：延迟调用参数 launch::deferred和强制创建线程参数 launch::async

如果系统资源紧张，那么使用 thread 创建线程可能会失败，执行 thread 时可能会引发程序崩溃

async 一般不叫创建线程，我们一般叫它创建一个【异步任务】，即使它也是创建了一个线程

async 和 thread 最明显的不同就是，有时候 async 并不创建新线程，（在使用参数 launch::deferred时）



**7.2.1 async 两个参数**

**示例：launch::deferred**

```c++
class myThread
{
public:
	int myprint(int a)
	{
		cout << "this thread id = " << this_thread::get_id() << endl;
		cout << a << endl;
		return 999;
	}
};

int main()
{
	cout << "main thread id = " << this_thread::get_id() << endl;
	myThread mythread;
	int para = 123456;
	future<int> res = async(launch::deferred, &myThread::myprint, ref(mythread), para);
	cout << res.get() << endl; // 开始调用线程入口函数

	system("pause");
	return 0;	
}

/*
	main thread id = 10176
	this thread id = 10176
	123456
	999
*/
```

> 当时用 launch::deferred 参数时，可以得到几个结论：
>
> （1）只有当 future 对象执行 .get() 或者 .wait() 时才会调用线程入口函数
>
> （2）此时 async 不会创建一个新线程，而是在执行 .get() 的线程内部调用线程入口函数
>
> （3）如果 future 对象没有执行 .get() 或者 .wait()，那么这个 async 创建的异步任务就是无意义的，既不会创建也不会执行



如果调用的时候同时使用两个参数，将会出现什么情况呢？

```c++
future<int> res = async(launch::deferred | launch::async, &myThread::myprint, ref(mythread), para);
```

launch::deferred | launch::async 这样调用两个参数将会将其全部置位，这里的【或操作】关系就意味着调用 async 的行为可能是：

（1）异步运行，创建新线程并立即执行，对应 launch::async

（2）同步运行，不创建新线程，并延迟调用，对应 launch::deferred

这两种行为具体采用哪一种，是由系统根据一定的因素去自行选择，可能是根据内存来选择，可能同步运行可能异步运行

**如果我们不手动键入参数，async的默认参数是 launch::deferred | launch::async**



**系统是如何自行决定异步执行还是同步执行的呢？**

首先明确 thread 和 async 的区别：

（1）用 thread 创建线程，如果系统资源紧张，创建线程失败，那么整个程序就会报异常崩溃

（2）thread 创建线程的方式，如果子线程有返回值，那么可能需要定义一些全局变量来接收这个值

（3）async 很容易拿到线程入口函数的返回值，用 future 对象来接收

由于系统资源限制，如果用 thread 创建的线程太多，则可能创建失败，系统崩溃

如果用 async 一般就不会报异常，是因为系统资源紧张导致无法创建新线程的时候，async 的缺省参数调用方式就不会继续创建新线程了

而是后续哪个 future 调用了 .get() 来请求结果，就会在这条语句所在的线程调用线程入口函数（不会创建新线程）



如果你强制 async 一定要创建新线程，就必须使用 launch::async，所承受的代价就是系统资源紧张时，程序崩溃

当然如果你能写出让系统资源紧张的代码，那也不只是线程多的问题了 --!

一个程序里的线程数量不宜超过100-200



**7.2.2 async 不确定性问题的解决**

对于缺省参数的 async 调用，我们自己无法决定系统会不会创建新线程，那么就存在了一定的不确定性

这个异步任务到底有没有被推迟执行 如何确定？？

就是 future::wait_for() 的三个枚举量就可以判断系统是如何启动这个线程入口函数的，跳转到 7.5 future

```c++
class myThread
{
public:
	int myprint(int a)
	{
		cout << "this thread id = " << this_thread::get_id() << endl;
		cout << a << endl;
		return 999;
	}
};

int main()
{
	cout << "main thread id = " << this_thread::get_id() << endl;
	myThread mythread;
	int para = 123456;
	future<int> res = async(&myThread::myprint, ref(mythread), para);
	// 我想判断 async 到底有没有给我创建一个新线程
	future_status status = res.wait_for(chrono::milliseconds(0)); // wait for 0ms
	if (status == future_status::deferred)
	{
		// 线程被延迟执行了（系统资源紧张）
		cout << res.get() << endl; // 这时才去调用 myprint
	}
	else
	{
		// 任务没被推迟，线程被创建出来了
		if (status == future_status::ready)
		{
			cout << "线程已经运行完了" << endl;
			cout << res.get() << endl;
		}
		else if (status == future_status::timeout)
		{
			cout << "线程还没执行完呢" << endl;
			cout << res.get() << endl;
		}
	}
	system("pause");
	return 0;	
}
```





### 7.3 packaged_task

打包任务，把任务包装起来。这是一个类模板，它的模板参数是各种可调用对象

通过std::packaged_task来把各种可调用对象包装起来，方便将来作为线程入口函数

packaged_task包装起来的可调用对象还可以直接调用，所以从这个角度来讲，packaged_task也是一个可调用对象

其中的 <int(int)> 的含义是：小括号内部的是线程函数的参数类型，小括号外部的是返回值的类型

**示例**

```c++
std::packaged_task<int(int)> mypt1(mythread);
std::packaged_task<int(int)> mypt2([](int para) {
	cout << para << endl;
	cout << "mythread() start" << "thread id = " << std::this_thread::get_id() << endl;
	std::chrono::milliseconds dura(5000);
	std::this_thread::sleep_for(dura);
	return 5;
});

std::thread t1(std::ref(mypt1),1);
t1.join();

// 取函数返回结果
std::future<int> res = mypt1.get_future();
cout << res.get() << endl;
```



可以把packaged_task对象放在一个容器中，方便后续调用

```c++
vector<std::packaged_task<int(int)>> mytasks;
mytasks.push_back(std::move(mypt1));  // mypt1已经在上文通过packaged_task创建了，注意使用转移语意，防止重复创建对象
auto iter = mytasks.begin();
std::packaged_task<int(int)> mypt3 = std::move(*iter); // 把mypt1转移到mypt3
mytasks.erase(iter);
mypt3(123);
std::future<int> res = mypt3.get_future();
cout << res.get() << endl;
```



### 7.4 promise

std::promise 也是一个类模板

我们可以在某个线程中给其赋值，然后在另一个线程中取出来用

实现两个线程之间的数据传递（当然传递的方式有很多种，这只是其中一种）



**示例**

```c++
void mythread(std::promise<int>&tmpp, int calc) // 这里要接收一个promise对象
{
	cout << "mythread start..." << endl;
	cout << "thread id = " << std::this_thread::get_id() << endl;
	calc++;
	calc *= 10;
	std::chrono::milliseconds dura(5000);
	std::this_thread::sleep_for(dura);
	int res = calc;
	tmpp.set_value(res);  // 给std::promise赋值，那么res这个值就被保存到tmpp这个对象中去了
	cout << "mythread end" << endl;
}

void mythread2(std::future<int>&res)
{
	cout << "mythread2 start..." << endl;
	cout << "thread id = " << std::this_thread::get_id() << endl;
	cout << "the received value is " << res.get() << endl;
	cout << "mythread2 end" << endl;
}

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;

	std::promise<int> myprom;
	std::thread t1(mythread, std::ref(myprom), 190);
	t1.join();
	// 获取结果值
	std::future<int> res = myprom.get_future(); // 获取结果值
	std::thread t2(mythread2, std::ref(res)); // 将其传递给另一个线程
	t2.join();
	cout << "main thread end" << endl;
	return 0;
}
```



### 7.5 future

前面在 async 和 packaged_task 内容里使用过了 future 的一个重要的成员函数 .get()，对于一个简单的 future 对象，只能 .get() 一次，因为 .get() 是转移语意，当调用一次之后 future 对象中的值就会被清空。因此一个 future 对象只允许被 .get() 一次。

get()函数的设计是一个移动语义，第二次get()时这个future是empty，会异常

下面是另一个重要的成员函数 .wait_for()

.wait_for() 会把返回赋值给另一个枚举变量 std::future_status

future_status 有三种状态：std::future_status::timeout，std::future_status::ready，std::future_status::deferred



**示例**

```c++
int mythread(int para)
{
	cout << "mythread start" << endl;
	cout << "mythread id = " << std::this_thread::get_id() << endl;
	cout << "para = " << para << endl;

	std::chrono::seconds dura(5);
	std::this_thread::sleep_for(dura); // 假设此线程要执行 5s

	cout << "mythread end" << endl;
	return 999;
}

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	int para = 1111;
	std::future<int> res = std::async(mythread, para);

	std::future_status status = res.wait_for(std::chrono::seconds(10));
	if (status == std::future_status::timeout)
	{
		cout << "超时了，线程还没有执行完" << endl;
	}
	else if (status == std::future_status::ready)
	{
		cout << "线程已经执行完毕" << endl;
		cout << res.get() << endl;
	}
	else if (status == std::future_status::deferred)
	{
		cout << "线程被延迟创建（执行）" << endl;
		cout << res.get() << endl;
	}

	cout << "main thread end" << endl;
	return 0;
}
```



wait_for()的含义很简单，就是让程序在此卡一定的时间，如果这个时间大于了子线程的执行时间，则 status 的状态就会为 ready，否则将会为 timeout，当然即使其状态为 timeout 也并不代表未执行完的子线程将会被强制退出，而是在 wait_for() 的时间内，子线程没有执行完毕而已。

另一个状态deferred是搭配 std::async的第一个参数 std::launch::deferred来使用的，下面是一个具体演示



**示例**

```c++
int mythread(int para)
{
	cout << "mythread start" << endl;
	cout << "mythread id = " << std::this_thread::get_id() << endl;
	cout << "para = " << para << endl;

	std::chrono::seconds dura(5);
	std::this_thread::sleep_for(dura); // 假设此线程要执行 5s

	cout << "mythread end" << endl;
	return 999;
}

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	int para = 1111;
	std::future<int> res = std::async(std::launch::deferred, mythread, para);

	std::future_status status = res.wait_for(std::chrono::seconds(10));
	if (status == std::future_status::deferred)
	{
		cout << "线程被延迟创建（执行）" << endl;
		cout << res.get() << endl;  //在此才会调用子线程入口函数 mythread，并将其创建在主线程中
	}
	cout << "main thread end" << endl;
	return 0;
}
```



### 7.6 shared_future

针对future对象，get()只能调用一次，如果有其他线程同样需要这个future::get()的值，future就无法正常使用了

因此引入了 shared_future 这个类模板

std::future::get() 是函数转移数据

std::shared_future::get() 是函数复制数据，因此允许重复访问



**示例**

```c++
int mythread(int para)
{
	cout << "mythread start" << endl;
	cout << "mythread id = " << std::this_thread::get_id() << endl;
	cout << "para = " << para << endl;

	std::chrono::seconds dura(5);
	std::this_thread::sleep_for(dura); // 假设此线程要执行 5s

	cout << "mythread end" << endl;
	return 999;
}

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	int para = 1111;
	std::shared_future<int> res = std::async(mythread, para);

	cout << res.get() << endl;
	cout << res.get() << endl; // 这里可以 get() 两次了

	cout << "main thread end" << endl;
	return 0;
}
```



## 8 原子操作

互斥量是在多线程编程中保护共享数据的，lock()--操作共享数据--unlock()，有两个线程对一个变量进行操作，一个读一个写

可以把原子操作理解为：不需要互斥量加锁解锁技术的多线程并发编程方式

原子操作的概念：在多线程中不会被打断的程序执行片段

原子操作是一种无锁技术，效率上来讲比互斥量高一些

互斥量加锁往往是针对一个代码段，原子操作针对的一般都是一个变量，而不是一个代码段

在计算机语言中，原子操作一般就是指不可分割的操作，这种操作的状态要么是完成的，要么是未完成的，不存在中间状态

std::atomic来代表原子操作，这是一个类模板，其实std::atomic是用来封装某个值的



### 8.1 atomic 用法范例

首先为了证实 atomic 相比于 mutex 加锁解锁的方式更加高效，下面的两个多线程程序将会对一个变量进行累加操作，加到两千万次

我们可以从中看到两种写法的运行时间



**示例1：使用mutex**

```c++
class myThread
{
private:
	std::mutex mymutex;
public:
	int mycnt = 0;
public:
	void mycount()
	{
		for (int i = 0; i < 10000000; ++i)
		{
			std::unique_lock<std::mutex> sbguard(mymutex);
			mycnt++;
		}
	}
};

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	myThread mythread;
	std::thread t1(&myThread::mycount, std::ref(mythread));
	std::thread t2(&myThread::mycount, std::ref(mythread));
	t1.join();
	t2.join();
	cout << mythread.mycnt << endl;  // 使用 mutex 大概执行8s

	cout << "main thread end" << endl;
	return 0;
}
```

> 使用 mutex 加锁解锁的方式操作同一个变量累加两千万次大概需要 **8s** 的时间



**示例2：使用atomic**

```c++
class myThread
{
private:
	std::mutex mymutex;
public:
	std::atomic<int> mycnt = 0;
public:
	void mycount()
	{
		for (int i = 0; i < 10000000; ++i)
		{
			mycnt++;
		}
	}
};

int main()
{
	cout << "main thread start ..." << endl;
	cout << "main thread id = " << std::this_thread::get_id() << endl;
	myThread mythread;
	std::thread t1(&myThread::mycount, std::ref(mythread));
	std::thread t2(&myThread::mycount, std::ref(mythread));
	t1.join();
	t2.join();
	cout << mythread.mycnt << endl;  // 使用 atomic 大概执行2s

	cout << "main thread end" << endl;
	return 0;
}
```

> 通过将 mycnt 声明为原子变量，执行时间大概为 **2s**



在示例2中，我们将执行原子操作的那一句代码作如下修改，可以得到一些原子操作的执行规律

```c++
mycnt++;            // right
mycnt += 1;         // right
mycnt = mycnt + 1;  // wrong，这是不支持的

```

> **一般原子操作针对， ++ , -- , += , &= , |= , ^= 是支持的**



### 8.2 原子操作细谈

下面这种初始化语句是不被允许的！

```c++
atomic<int> atm = 0; // valid
atomic<int> atm2 = atm; // invalid
atomic<int> atm3;
atm3 = atm; // invalid
```

第二种定义时初始化的操作不允许，系统异常提示 【尝试引用已删除的函数】

这是因为编译器内部把 atomic 这个类的拷贝构造函数给干掉了，比如使用 =delete 这种形式



如果想要以拷贝构造的方式进行初始化操作，atomic 提供了一个 .load() 接口，可以完成这种操作

load() 是以原子方式读 atomic 对象的值

```c++
atomic<int> atm = 0;
atomic<int> atm2(atm.load()); // valid
auto atm3(atm.load()); // valid
```

store() 是以原子方式写入内容

```c++
atomic<int> atm.store(12); // valid
atomic<int> atm2 = 12; // valid
```



## 9 windows临界区

windows 临界区是只针对 windows 开发环境而言的，其作用与 mutex 非常相似，只是 mutex 是跨平台的，临界区只针对 windows

用的时候引入头文件 <windows.h>



### 9.1 临界区基本用法

临界区的用法与 mutex 几乎一模一样，下面这段代码演示了 c++11 使用 mutex 和 windows 下使用临界区的共存的一段代码。

**示例**

```c++
#include<iostream>
#include<string>
#include<thread>
#include<mutex>
#include<list>
#include<windows.h>

using namespace std;

#define __WINDOWSJQ_

class A
{
private:
	list<int> msgRecvQueue;
	mutex m_mutex;
#ifdef __WINDOWSJQ_
	CRITICAL_SECTION my_winsec;  // 定义windows中的临界区
#endif // __WINDOWSJQ_

public:
	A()
	{
#ifdef __WINDOWSJQ_
		InitializeCriticalSection(&my_winsec); // 使用临界区之前需要初始化
											   // 在构造函数里初始化就行
#endif // __WINDOWSJQ_

	}

	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
#ifdef __WINDOWSJQ_
			EnterCriticalSection(&my_winsec); // 进入临界区
			msgRecvQueue.push_back(i);
			LeaveCriticalSection(&my_winsec); // 离开临界区
#else
			m_mutex.lock();
			msgRecvQueue.push_back(i);
			m_mutex.unlock();
#endif // DEBUG
		}
	}

	void outMsgRecvQueue()
	{
		int cmd = 0;
		for (int i = 0; i < 100000; ++i)
		{
			if (outMsgLULProc(cmd))
			{
				cout << "outMsgRecvQueue() 正在执行，取出一个元素" << cmd << endl;
			}
			else
			{
				cout << "outMsgRecvQueue() 正在执行，但目前队列中没有消息" << endl;
			}
		}
	}

	bool outMsgLULProc(int &cmd)
	{
#ifdef __WINDOWSJQ_
		EnterCriticalSection(&my_winsec); // 进入临界区
		if (!msgRecvQueue.empty())
		{
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			LeaveCriticalSection(&my_winsec); // 离开临界区
			return true;
		}
		LeaveCriticalSection(&my_winsec); // 离开临界区
		return false;
#else
		m_mutex.lock();
		if (!msgRecvQueue.empty())
		{
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			m_mutex.unlock();
			return true;
		}
		m_mutex.unlock();
		return false;
#endif // __WINDOWSJQ_
	}
};

int main()
{
	A a;
	thread t1(&A::outMsgRecvQueue, ref(a));
	thread t2(&A::inMsgRecvQueue, ref(a));
	t1.join();
	t2.join();

	system("pause");
	return 0;
}
```



### 9.2 多次进入临界区试验

在 C++11 中不允许对一个 mutex 对象多次上锁解锁，但在 windows 中可以多次进入临界区

但是其遵循的是一个计数原则，如果你进了三次临界区，那么就要出三次才可以！

```c++
EnterCriticalSection(&my_winsec); // 第一次进入临界区
EnterCriticalSection(&my_winsec); // 第二次进入临界区
msgRecvQueue.push_back(i);
LeaveCriticalSection(&my_winsec); // 第一次离开临界区
LeaveCriticalSection(&my_winsec); // 第二次离开临界区
```



**结论：**

在同一个线程中，windows 中的相同临界区变量代表的临界区，可以多次进入临界区的。但是你调用几次进入临界区就要调用几次离开临界区



### 9.3 自动析构技术

参考 C++11 中的 lock_guard，当其离开作用域时会自动析构，析构函数会自动解锁mutex，从而实现了我们不用自己解锁，类似于如下情况

```c++
{
	lock_guard<mutex> sbguard(m_mutex);
	msgRecvQueue.push_back(i);
}
```



下面我们来做 windows 语言中，自动析构的实现，用来实现当临界区离开作用域时，会自动离开临界区



**示例**

```c++
#include<iostream>
#include<string>
#include<thread>
#include<mutex>
#include<list>
#include<windows.h>

using namespace std;

#define __WINDOWSJQ_

// 本类用于自动释放 windows 下的临界区
// 防止忘记离开临界区而导致的死锁现象
// 类似于 C++11 中的 lock_guard
class CWinLock
{
public:
	CWinLock(CRITICAL_SECTION *p) 
	{
		this->m_pCritical = p;
		EnterCriticalSection(m_pCritical); // 构造的时候进入临界区
	}
	~CWinLock()
	{
		LeaveCriticalSection(m_pCritical); // 析构的时候离开临界区
	}
private:
	CRITICAL_SECTION *m_pCritical;
};

class A
{
private:
	list<int> msgRecvQueue;
	mutex m_mutex;
#ifdef __WINDOWSJQ_
	CRITICAL_SECTION my_winsec;  // 定义windows中的临界区
#endif // __WINDOWSJQ_

public:
	A()
	{
#ifdef __WINDOWSJQ_
		InitializeCriticalSection(&my_winsec); // 使用临界区之前需要初始化
											   // 在构造函数里初始化就行
#endif // __WINDOWSJQ_

	}

	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
#ifdef __WINDOWSJQ_
			CWinLock winlock(&my_winsec);  // 实现临界区的自动析构
			msgRecvQueue.push_back(i);
#else
			lock_guard<mutex> sbguard(m_mutex);
			msgRecvQueue.push_back(i);
#endif // DEBUG
		}
	}

	void outMsgRecvQueue()
	{
		int cmd = 0;
		for (int i = 0; i < 100000; ++i)
		{
			if (outMsgLULProc(cmd))
			{
				cout << "outMsgRecvQueue() 正在执行，取出一个元素" << cmd << endl;
			}
			else
			{
				cout << "outMsgRecvQueue() 正在执行，但目前队列中没有消息" << endl;
			}
		}
	}

	bool outMsgLULProc(int &cmd)
	{
#ifdef __WINDOWSJQ_
		CWinLock winlock(&my_winsec);
		if (!msgRecvQueue.empty())
		{
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			return true;
		}
		return false;
#else
		m_mutex.lock();
		if (!msgRecvQueue.empty())
		{
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			m_mutex.unlock();
			return true;
		}
		m_mutex.unlock();
		return false;
#endif // __WINDOWSJQ_
	}
};

int main()
{
	A a;
	thread t1(&A::outMsgRecvQueue, ref(a));
	thread t2(&A::inMsgRecvQueue, ref(a));
	t1.join();
	t2.join();

	system("pause");
	return 0;
}
```



这种 CWinLock 类叫做 **RAII** 类，Resource Acquisition is initialization，中文叫做 【资源获取即初始化】

这种类的特点就是在构造函数中获取一个资源，在析构函数中释放这个资源

这种类在C++11中有：智能指针，容器，lock_guard等等



## 10 其他 mutex 互斥量

### 10.1 recursive_mutex

recursive_mutex被叫做递归的独占互斥量

有可能我会书写出如下代码，这时候如果用 mutex 的话是一定会报错的

```c++
class Test
{
private:
	mutex m_mutex;
public:
	void testfunc1()
	{
		lock_guard<mutex> sbguard(m_mutex);
		// ...处理共享数据
	}

	void testfunc2()
	{
		lock_guard<mutex> sbguard(m_mutex);
		// ...处理共享数据
		testfunc1(); // 异常，因为加了两次锁
	}
};
```

在上述的代码中，会存在异常。因为我在 testfunc2 中调用 testfunc1 就相当于对同一个互斥量加了两次锁了

其实 mutex 也被叫做独占互斥量，顾名思义就是其只允许被同一个线程加锁一次

recursive_mutex：递归的独占互斥量，允许同一个线程，同一个互斥量被多次 lock



那么将上述代码写成如下形式就将会是正确的，其中将m_mutex的类型声明为 recursive_mutex

这更类似于 windows 中的临界区的概念

```c++
class Test
{
private:
	recursive_mutex m_mutex;
public:
	void testfunc1()
	{
		lock_guard<mutex> sbguard(m_mutex);
		// ...处理共享数据
	}

	void testfunc2()
	{
		lock_guard<mutex> sbguard(m_mutex);
		// ...处理共享数据
		testfunc1(); // 异常，因为加了两次锁
	}
};
```

当然如果真的使用了 recursive_mutex，要考虑代码是否可以优化以使用 mutex，因为 recursive_mutex 的执行效率比 mutex 低

递归次数据说是有限制的，递归太多会出现异常



### 10.2 timed_mutex

带超时功能的独占互斥量

提供了两个新接口：try_lock_for() 和 try_lock_until()

（1）try_lock_for() ：等待一段时间，如果我们拿到了锁或者等待超过时间没拿到锁，都会继续向下执行

（2）try_lock_until()：参数是一个未来的时间点，在这个时间点没到的时间段内，如果拿到了锁流程就走下去；如果到了这个时间点但是没拿到锁，程序也会走下来。其实和 try_lock_for() 是一样的，只是写法有点不同



**try_lock_for() 示例**

```c++
class A
{
private:
	list<int> msgRecvQueue;
	timed_mutex m_mutex;

public:
	void inMsgRecvQueue()
	{
		for (int i = 0; i < 100000; ++i)
		{
			cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
			chrono::milliseconds timeout(100);
			if (m_mutex.try_lock_for(timeout)) // 等待100ms尝试获取锁
			{
				// 在100ms内拿到了锁头
				msgRecvQueue.push_back(i);
				m_mutex.unlock();
			}
			else
			{
				// 没拿到锁头
				cout << "sleep ... ..." << endl; // 这一句每隔 100ms 执行一次的
				chrono::milliseconds sleeptime(100);
				this_thread::sleep_for(sleeptime);
			}
		}
	}

	void outMsgRecvQueue()
	{
		int cmd = 0;
		for (int i = 0; i < 100000; ++i)
		{
			if (outMsgLULProc(cmd))
			{
				cout << "outMsgRecvQueue() 正在执行，取出一个元素" << cmd << endl;
			}
			else
			{
				cout << "outMsgRecvQueue() 正在执行，但目前队列中没有消息" << endl;
			}
		}
	}

	bool outMsgLULProc(int &cmd)
	{
		m_mutex.lock();

		chrono::milliseconds dura(1000000);
		this_thread::sleep_for(dura);

		if (!msgRecvQueue.empty())
		{
			cmd = msgRecvQueue.front();
			msgRecvQueue.pop_front();
			m_mutex.unlock();
			return true;
		}
		m_mutex.unlock();
		return false;
	}
};

int main()
{
	A a;
	thread t1(&A::outMsgRecvQueue, ref(a));
	thread t2(&A::inMsgRecvQueue, ref(a));
	t1.join();
	t2.join();

	system("pause");
	return 0;
}
```



**try_lock_until() 示例**

```c++
chrono::milliseconds timeout(100);
if (m_mutex.try_lock_until(chrono::steady_clock::now() + timeout)) // 等待100ms尝试获取锁
{
	// 在100ms内拿到了锁头
	msgRecvQueue.push_back(i);
	m_mutex.unlock();
	cout << "inMsgRecvQueue() 执行，插入一个元素" << i << endl;
}
else
{
	// 没拿到锁头
	cout << "sleep ... ..." << endl;
	chrono::milliseconds sleeptime(100);
	this_thread::sleep_for(sleeptime);
}
```



### 10.3 recursive_timed_mutex

带超时功能的递归独占互斥量，就是 timed_mutex 和 recursive_mutex 的结合体，不在此详解。



## 11 LeetCode 题目

### 11.1 按序打印

lc 第1114 题

我们创建了一个类：

```java
public class Foo
{
    public void first() {print("first");}
    public void second() {print("second");}
    public void thrid() {print("third");}
}
```

三个不同的线程A、B、C 将会共用一个 Foo 实例。

一个将会调用 first() 方法

一个将会调用 second() 方法

一个将会调用 third() 方法

请设计修改程序，以确保 second() 在 first() 之后被执行，third() 在 second() 之后被执行。

**示例1**

```c++
输入: [1,2,3]
输出: "firstsecondthird"
解释: 
有三个线程会被异步启动。
输入 [1,2,3] 表示线程 A 将会调用 first() 方法，线程 B 将会调用 second() 方法，线程 C 将会调用 third() 方法。
正确的输出是 "firstsecondthird"。
```



**11.1.1 使用 mutex**

针对这道题我们可以用两个互斥量来阻塞 second 和 third 函数，分别在 first 和 second 执行结束后解锁

```c++
class Foo {
	mutex m_mutex1, m_mutex2;
public:
	Foo() {
		m_mutex1.lock();
		m_mutex2.lock();
	}

	void first(function<void()> printFirst) {
		// printFirst() outputs "first". Do not change or remove this line.
		printFirst();
		m_mutex1.unlock();

	}

	void second(function<void()> printSecond) {
		m_mutex1.lock();
		// printSecond() outputs "second". Do not change or remove this line.
		printSecond();
		m_mutex1.unlock();
		m_mutex2.unlock();
	}

	void third(function<void()> printThird) {
		m_mutex2.lock();
		// printThird() outputs "third". Do not change or remove this line.
		printThird();
		m_mutex2.unlock();
	}
};
```

这段代码能够 ac，但实际上这种使用 mutex 的方法是错误的，因为根据 c++ 标准，在一个线程尝试对一个 mutex 对象进行 unlock 操作时，mutex 对象的所有权必须在这个线程上；也就是说，应该由同一个线程来对一个 mutex 对象进行 lock 和 unlock 操作，否则会产生未定义行为。题目中提到了 first, second, third 三个函数分别是由三个不同的线程来调用的，但我们是在 Foo 对象构造时（可以是在 create 这几个线程的主线程中，也可以是在三个线程中的任意一个）对两个 mutex 对象进行 lock 操作的，因此，调用 first 和 second 函数的两个线程中至少有一个在尝试获取其他线程所拥有的 mutex 对象的所有权。



**11.1.2 条件变量**

条件变量一般和互斥锁搭配使用，互斥锁用于上锁，条件变量用于在多线程环境中等待特定事件发生。

针对这道题我们可以分别在 first 和 second 执行完之后修改特定变量的值（例如修改成员变量 k 为特定值），然后通知条件变量，唤醒下一个函数继续执行。

```c++
class Foo {
	condition_variable m_cond;
	mutex m_mutex;
	int k = 0;
public:
	Foo() {
	}

	void first(function<void()> printFirst) {
		// printFirst() outputs "first". Do not change or remove this line.
		printFirst();
		k = 1;
		m_cond.notify_all();
	}

	void second(function<void()> printSecond) {
		unique_lock<mutex> lock(m_mutex);
		m_cond.wait(lock, [this]() {return k == 1; });  // 解决虚假唤醒
		// printSecond() outputs "second". Do not change or remove this line.
		printSecond();
		k = 2;
		m_cond.notify_one();
	}

	void third(function<void()> printThird) {
		unique_lock<mutex> lock(m_mutex);
		m_cond.wait(lock, [this]() {return k == 2; });
		// printThird() outputs "third". Do not change or remove this line.
		printThird();
	}
};
```



**11.1.3 信号量**

信号量是用来实现对共享资源的同步访问的机制，其使用方法和条件变量类似，都是通过主动等待和主动唤醒来实现的。

c++ 标准库中并没有信号量的实现和封装，我们可以用 c 语言提供的 `<sempahore.h>` 库来解题 ：

```c++
#include <semaphore.h>

class Foo {
private:
    sem_t sem_1, sem_2;

public:
    Foo() {
        sem_init(&sem_1, 0, 0), sem_init(&sem_2, 0, 0);
    }

    void first(function<void()> printFirst) {
        printFirst();
        sem_post(&sem_1);
    }

    void second(function<void()> printSecond) {
        sem_wait(&sem_1);
        printSecond();
        sem_post(&sem_2);
    }

    void third(function<void()> printThird) {
        sem_wait(&sem_2);
        printThird();
    }
};
```



**11.1.4 异步任务**

异步操作是一种，在不需要等待被调用方返回结果之前，就让操作继续进行下去的方法。针对这道题可以使用基于 future/promise 的异步编程模型。

future 和 promise 起源于函数式编程，其目的是将值（future）和计算方式（promise）分离，使得 promise 可以异步地修改 future，从而提高代码的可读性，并减少通信延迟。

std::future 是用来获取异步操作结果的模板类；std::packaged_task, std::promise, std::async 都可以进行异步操作，并拥有一个 std::future 对象，用来存储它们所进行的异步操作返回或设置的值（或异常），这个值会在将来的某一个时间点，通过某种机制被修改后，保存在其对应的 std::future 对象中：

对于 std::promise，可以通过调用 std::promise::set_value 来设置值并通知 std::future 对象：

```c++
class Foo {
	promise<void> pro1, pro2;
public:
	void first(function<void()> printFirst) {
		printFirst();
		pro1.set_value();
	}

	void second(function<void()> printSecond) {
		pro1.get_future().wait();
		printSecond();
		pro2.set_value();
	}

	void third(function<void()> printThird) {
		pro2.get_future().wait();
		printThird();
	}
};
```



**11.1.5 原子操作**

我们平时进行的数据修改都是非原子操作，如果多个线程同时以非原子操作的方式修改同一个对象可能会发生数据争用，从而导致未定义行为；而原子操作能够保证多个线程顺序访问，不会导致数据争用，其执行时没有任何其它线程能够修改相同的原子对象。

针对这道题，我们可以让 second 和 third 函数等待原子变量被修改为某个值后再执行，然后分别在 first 和 second 函数中来修改这个原子变量。

```c++
class Foo {
	atomic<bool> atm1 = false;
	atomic<bool> atm2 = false;
public:
	void first(function<void()> printFirst) {
		printFirst();
		atm1 = true;
	}

	void second(function<void()> printSecond) {
		while (!atm1)
			this_thread::sleep_for(chrono::milliseconds(1));
		printSecond();
		atm2 = true;
	}

	void third(function<void()> printThird) {
		while (!atm2)
			this_thread::sleep_for(chrono::milliseconds(1));
		printThird();
	}
};
```



### 11.2 交替打印FooBar

lc 第1115题

我们提供一个类：

```java
class FooBar {
  public void foo() {
    for (int i = 0; i < n; i++) {
      print("foo");
    }
  }

  public void bar() {
    for (int i = 0; i < n; i++) {
      print("bar");
    }
  }
}
```

两个不同的线程将会共用一个 FooBar 实例。其中一个线程将会调用 foo() 方法，另一个线程将会调用 bar() 方法。

请设计修改程序，以确保 "foobar" 被输出 n 次。

**示例1**

```
输入: n = 1
输出: "foobar"
解释: 这里有两个线程被异步启动。其中一个调用 foo() 方法, 另一个调用 bar() 方法，"foobar" 将被输出一次。
```



**11.2.1 原子操作**

```c++
class FooBar {
private:
	int n;
	atomic<int> atm;
public:
	FooBar(int n) {
		this->n = n;
		atm = 0;
	}

	void foo(function<void()> printFoo) {

		for (int i = 0; i < n; i++) {
			while (atm)
				this_thread::sleep_for(chrono::nanoseconds(1));
			printFoo();
			atm++;
		}
	}

	void bar(function<void()> printBar) {

		for (int i = 0; i < n; i++) {
			while (!atm)
				this_thread::sleep_for(chrono::nanoseconds(1));
			printBar();
			atm--;
		}
	}
};
```



**11.2.2 条件变量**

```c++
class FooBar {
private:
	int n;
	condition_variable m_cond;
	mutex m_mutex;
	bool foo_done;
public:
	FooBar(int n) {
		this->n = n;
		foo_done = false;
	}

	void foo(function<void()> printFoo) {

		for (int i = 0; i < n; i++) {
			unique_lock<mutex> sbguard(m_mutex);
			m_cond.wait(sbguard, [&]() {return foo_done == false; });
			printFoo();
			foo_done = true;
			m_cond.notify_one();
		}
	}

	void bar(function<void()> printBar) {

		for (int i = 0; i < n; i++) {
			unique_lock<mutex> sbguard(m_mutex);
			m_cond.wait(sbguard, [&]() {return foo_done == true; });
			printBar();
			foo_done = false;
			m_cond.notify_one();
		}
	}
};
```



**11.2.3 信号量**

```c++
#include<semaphore.h>
class FooBar {
private:
    int n;
    sem_t foo_done,bar_done;
public:
    FooBar(int n) {
        this->n = n;
        sem_init(&foo_done,0,0);
        sem_init(&bar_done,0,1);
    }
    void foo(function<void()> printFoo) {
        for (int i = 0; i < n; i++) {
            sem_wait(&bar_done);
            printFoo();
            sem_post(&foo_done);
        }
    }
    void bar(function<void()> printBar) {
        for (int i = 0; i < n; i++) {
            sem_wait(&foo_done);
            printBar();
            sem_post(&bar_done);
        }
    }
};
```



### 11.3 打印零和奇偶数

lc 1116题

假设有这么一个类：

```java
class ZeroEvenOdd {
  public ZeroEvenOdd(int n) { ... }      // 构造函数
  public void zero(printNumber) { ... }  // 仅打印出 0
  public void even(printNumber) { ... }  // 仅打印出 偶数
  public void odd(printNumber) { ... }   // 仅打印出 奇数
}
```

相同的一个 ZeroEvenOdd 类实例将会传递给三个不同的线程：

线程 A 将调用 zero()，它只输出 0 。

线程 B 将调用 even()，它只输出偶数。

线程 C 将调用 odd()，它只输出奇数。

每个线程都有一个 printNumber 方法来输出一个整数。请修改给出的代码以输出整数序列 010203040506... ，其中序列的长度必须为 2n。

**示例1**

```
输入：n = 2
输出："0102"
说明：三条线程异步执行，其中一个调用 zero()，另一个线程调用 even()，最后一个线程调用odd()。正确的输出为 "0102"。
```



**11.3.1 原子操作**

```c++
class ZeroEvenOdd {
private:
	int n;
	atomic<int> m_atom;
public:
	ZeroEvenOdd(int n) {
		this->n = n;
		m_atom = 0;
	}

	// printNumber(x) outputs "x", where x is an integer.
	void zero(function<void(int)> printNumber) {
		for (int i = 1; i <= n; ++i)
		{
			while (m_atom != 0)
				this_thread::yield();
                //this_thread::sleep_for(chrono::nanoseconds(1));
			printNumber(0);
			if (i % 2) m_atom = 2;
			else m_atom = 1;
		}
	}

	void even(function<void(int)> printNumber) {
		for (int i = 2; i <= n; i += 2)
		{
			while (m_atom != 1)
				this_thread::yield();
                //this_thread::sleep_for(chrono::nanoseconds(1));
			printNumber(i);
			m_atom = 0;
		}
	}

	void odd(function<void(int)> printNumber) {
		for (int i = 1; i <= n; i += 2)
		{
			while (m_atom != 2)
				this_thread::yield();
				//this_thread::sleep_for(chrono::nanoseconds(1));
			printNumber(i);
			m_atom = 0;
		}
	}
};
```

注意到上述使用原子操作调度线程执行的代码中与之前不同的是，在判断原子量没有满足线程执行条件的时候，使用的是this_thread::yield() 来进行等待处理，这里要说明一下这个函数与 this_thread::sleep_for() 区别之处

std::this_thread::yield() 的目的是避免一个线程(that should be used in a case where you are in a busy waiting state)频繁与其他线程争抢CPU时间片, 从而导致多线程处理性能下降

std::this_thread::yield() 是让当前线程让渡出自己的CPU时间片(给其他线程使用)

std::this_thread::sleep_for() 是让当前休眠”指定的一段”时间

sleep_for()也可以起到 std::this_thread::yield()相似的作用, (即:当前线程在休眠期间, 自然不会与其他线程争抢CPU时间片)但两者的使用目的是大不相同的:

**std::this_thread::yield() 是让线程让渡出自己的CPU时间片(给其他线程使用)**

**sleep_for() 是线程根据某种需要, 需要等待若干时间**



**11.3.2 条件变量**

通过上面两个例题大概可以看出使用条件变量代替C语言中信号量的使用方法，大多数情况下在调度线程执行顺序时，都会用一个 bool 变量来进行指示，然后在 .wait() 中加入第二个参数来防止虚假唤醒，防止程序死锁。

```c++
class ZeroEvenOdd {
private:
	int n;
	condition_variable m_cond;
	bool evenPrint, oddPrint, zeroPrint;
	mutex m_mutex;

public:
	ZeroEvenOdd(int n) {
		this->n = n;
		evenPrint = false;
		oddPrint = false;
		zeroPrint = true;
		m_cond.notify_all();
	}

	// printNumber(x) outputs "x", where x is an integer.
	void zero(function<void(int)> printNumber) {
		for (int i = 1; i <= n; ++i)
		{
			unique_lock<mutex> sblock(m_mutex);
			m_cond.wait(sblock, [&]() {return zeroPrint; });
			printNumber(0);
			zeroPrint = false;
			if (i % 2) oddPrint = true;
			else evenPrint = true;
			m_cond.notify_all();
		}
	}

	void even(function<void(int)> printNumber) {
		for (int i = 2; i <= n; i += 2)
		{
			unique_lock<mutex> sblock(m_mutex);
			m_cond.wait(sblock, [&]() {return evenPrint; });
			printNumber(i);
			evenPrint = false;
			zeroPrint = true;
			m_cond.notify_all();
		}
	}

	void odd(function<void(int)> printNumber) {
		for (int i = 1; i <= n; i += 2)
		{
			unique_lock<mutex> sblock(m_mutex);
			m_cond.wait(sblock, [&]() {return oddPrint; });
			printNumber(i);
			oddPrint = false;
			zeroPrint = true;
			m_cond.notify_all();
		}
	}
};
```



### 11.4 H2O生成

lc 第1117题

现在有两种线程，氧 oxygen 和氢 hydrogen，你的目标是组织这两种线程来产生水分子。

存在一个屏障（barrier）使得每个线程必须等候直到一个完整水分子能够被产生出来。

氢和氧线程会被分别给予 releaseHydrogen 和 releaseOxygen 方法来允许它们突破屏障。

这些线程应该三三成组突破屏障并能立即组合产生一个水分子。

你必须保证产生一个水分子所需线程的结合必须发生在下一个水分子产生之前。

换句话说:

如果一个氧线程到达屏障时没有氢线程到达，它必须等候直到两个氢线程到达。
如果一个氢线程到达屏障时没有其它线程到达，它必须等候直到一个氧线程和另一个氢线程到达。
书写满足这些限制条件的氢、氧线程同步代码。

**示例1**

```
输入: "HOH"
输出: "HHO"
解释: "HOH" 和 "OHH" 依然都是有效解。
```



通俗理解这个线程的工作方式，即 releaseHydrogen 执行两次，releaseOxygen 执行一次，这就是一个 HHO 分子，如此循环即可。



**11.4.1 原子操作**

```c++
class H2O {
	atomic<int> m_atm;
public:
	H2O() {
		m_atm = 0;
	}

	void hydrogen(function<void()> releaseHydrogen) {
		while (m_atm > 1)
			this_thread::yield();
		releaseHydrogen();
		m_atm++;
	}

	void oxygen(function<void()> releaseOxygen) {
		while (m_atm < 2)
			this_thread::yield();
		releaseOxygen();
		m_atm = 0;
	}
};
```



**11.4.2 条件变量**

```c++
class H2O {
	mutex m_mutex;
	condition_variable m_cond;
	int state;
public:
	H2O() {
		state = 0;
	}

	void hydrogen(function<void()> releaseHydrogen) {
		unique_lock<mutex> tlock(m_mutex);
		m_cond.wait(tlock, [&]() {return state < 2; });
		releaseHydrogen();
		state++;
		m_cond.notify_one();
	}

	void oxygen(function<void()> releaseOxygen) {
		unique_lock<mutex> tlock(m_mutex);
		m_cond.wait(tlock, [&]() {return state == 2; });
		releaseOxygen();
		state = 0;
		m_cond.notify_all();
	}
};
```



### 11.5 设计有限阻塞队列

lc 第1188题

实现一个拥有如下方法的线程安全有限阻塞队列：

BoundedBlockingQueue(int capacity) 构造方法初始化队列，其中capacity代表队列长度上限。
void enqueue(int element) 在队首增加一个element. 如果队列满，调用线程被阻塞直到队列非满。
int dequeue() 返回队尾元素并从队列中将其删除. 如果队列为空，调用线程被阻塞直到队列非空。
int size() 返回当前队列元素个数。
你的实现将会被多线程同时访问进行测试。每一个线程要么是一个只调用enqueue方法的生产者线程，要么是一个只调用dequeue方法的消费者线程。size方法将会在每一个测试用例之后进行调用。

请不要使用内置的有限阻塞队列实现，否则面试将不会通过。

**示例1**

```
输入:
1
1
["BoundedBlockingQueue","enqueue","dequeue","dequeue","enqueue","enqueue","enqueue","enqueue","dequeue"]
[[2],[1],[],[],[0],[2],[3],[4],[]]

输出:
[1,0,2,2]

解释:
生产者线程数目 = 1
消费者线程数目 = 1

BoundedBlockingQueue queue = new BoundedBlockingQueue(2);   // 使用capacity = 2初始化队列。

queue.enqueue(1);   // 生产者线程将1插入队列。
queue.dequeue();    // 消费者线程调用dequeue并返回1。
queue.dequeue();    // 由于队列为空，消费者线程被阻塞。
queue.enqueue(0);   // 生产者线程将0插入队列。消费者线程被解除阻塞同时将0弹出队列并返回。
queue.enqueue(2);   // 生产者线程将2插入队列。
queue.enqueue(3);   // 生产者线程将3插入队列。
queue.enqueue(4);   // 生产者线程由于队列长度已达到上限2而被阻塞。
queue.dequeue();    // 消费者线程将2从队列弹出并返回。生产者线程解除阻塞同时将4插入队列。
queue.size();       // 队列中还有2个元素。size()方法在每组测试用例最后调用。
```



**11.5.1 条件变量**

```c++
class BoundedBlockingQueue {
private:
	deque<int> msgRecvQueue;
	int maxCap;
	atomic<int> curCap = 0;
	mutex m_mutex;
	condition_variable m_cond;
public:
	BoundedBlockingQueue(int capacity) :maxCap(capacity) {}

	void enqueue(int element) {
		unique_lock<mutex> tlock(m_mutex);
		m_cond.wait(tlock, [&]() {return curCap < maxCap; });
		msgRecvQueue.push_front(element);
		curCap++;
		m_cond.notify_all();
	}

	int dequeue() {
		unique_lock<mutex> tlock(m_mutex);
		m_cond.wait(tlock, [&]() {return curCap > 0; });
		int val = msgRecvQueue.back();
		msgRecvQueue.pop_back();
		curCap--;
		m_cond.notify_all();
		return val;
	}

	int size() {
		return curCap;
	}
};
```



### 11.6 交替打印字符串

lc 第1195题

编写一个可以从 1 到 n 输出代表这个数字的字符串的程序，但是：

如果这个数字可以被 3 整除，输出 "fizz"。
如果这个数字可以被 5 整除，输出 "buzz"。
如果这个数字可以同时被 3 和 5 整除，输出 "fizzbuzz"。
例如，当 n = 15，输出： 1, 2, fizz, 4, buzz, fizz, 7, 8, fizz, buzz, 11, fizz, 13, 14, fizzbuzz。

假设有这么一个类：

```java
class FizzBuzz {
  public FizzBuzz(int n) { ... }               // constructor
  public void fizz(printFizz) { ... }          // only output "fizz"
  public void buzz(printBuzz) { ... }          // only output "buzz"
  public void fizzbuzz(printFizzBuzz) { ... }  // only output "fizzbuzz"
  public void number(printNumber) { ... }      // only output the numbers
}
```

请你实现一个有四个线程的多线程版  FizzBuzz， 同一个 FizzBuzz 实例会被如下四个线程使用：

1. 线程A将调用 fizz() 来判断是否能被 3 整除，如果可以，则输出 fizz。

2. 线程B将调用 buzz() 来判断是否能被 5 整除，如果可以，则输出 buzz。
3. 线程C将调用 fizzbuzz() 来判断是否同时能被 3 和 5 整除，如果可以，则输出 fizzbuzz。
4. 线程D将调用 number() 来实现输出既不能被 3 整除也不能被 5 整除的数字。



**11.6.1 条件变量**

与之前的多线程程序有点不同，在这个题目中存在线程无法主动退出的情况，而且.wait() 是在判断 cur <= n 之后的，其实这一句在 cur > n 之后并没有实际意义了，所以需要加入代码段中注释的那两句保证线程可以正常退出。

```c++
class FizzBuzz {
private:
	int n;
	int cur = 1;
	mutex m_mutex;
	condition_variable cv;
public:
	FizzBuzz(int n) {
		this->n = n;
	}

	// printFizz() outputs "fizz".
	void fizz(function<void()> printFizz) {
		while (cur <= n)
		{
			unique_lock<mutex> tlock(m_mutex);
            // 注意这两句，是为了防止线程无法退出而设计的
			cv.wait(tlock, [&]() {return cur > n || cur % 3 == 0 && cur % 5; });
			if (cur <= n)
			{
				cur++;
				printFizz();
			}
			cv.notify_all();
		}
	}

	// printBuzz() outputs "buzz".
	void buzz(function<void()> printBuzz) {
		while (cur <= n)
		{
			unique_lock<mutex> tlock(m_mutex);
			cv.wait(tlock, [&]() {return cur > n || cur % 5 == 0 && cur % 3; });
			if (cur <= n)
			{
				cur++;
				printBuzz();
			}
			cv.notify_all();
		}
	}

	// printFizzBuzz() outputs "fizzbuzz".
	void fizzbuzz(function<void()> printFizzBuzz) {
		while (cur <= n)
		{
			unique_lock<mutex> tlock(m_mutex);
			cv.wait(tlock, [&]() {return cur > n || cur % 3 == 0 && cur % 5 == 0; });
			if (cur <= n)
			{
				cur++;
				printFizzBuzz();
			}
			cv.notify_all();
		}
	}

	// printNumber(x) outputs "x", where x is an integer.
	void number(function<void(int)> printNumber) {
		while (cur <= n)
		{
			unique_lock<mutex> tlock(m_mutex);
			cv.wait(tlock, [&]() {return cur > n || cur % 3 && cur % 5; });
			if (cur <= n)
			{
				printNumber(cur);
				cur++;
			}
			cv.notify_all();
		}
	}
};
```



### 11.7 哲学家进餐

lc 第 1126 题

5 个沉默寡言的哲学家围坐在圆桌前，每人面前一盘意面。叉子放在哲学家之间的桌面上。（5 个哲学家，5 根叉子）

所有的哲学家都只会在思考和进餐两种行为间交替。哲学家只有同时拿到左边和右边的叉子才能吃到面，而同一根叉子在同一时间只能被一个哲学家使用。每个哲学家吃完面后都需要把叉子放回桌面以供其他哲学家吃面。只要条件允许，哲学家可以拿起左边或者右边的叉子，但在没有同时拿到左右叉子时不能进食。

假设面的数量没有限制，哲学家也能随便吃，不需要考虑吃不吃得下。

设计一个进餐规则（并行算法）使得每个哲学家都不会挨饿；也就是说，在没有人知道别人什么时候想吃东西或思考的情况下，每个哲学家都可以在吃饭和思考之间一直交替下去。

<img src="C:\Users\dell\Desktop\an_illustration_of_the_dining_philosophers_problem.png" alt="an_illustration_of_the_dining_philosophers_problem" style="zoom:50%;" />

哲学家从 0 到 4 按 顺时针 编号。请实现函数 void wantsToEat(philosopher, pickLeftFork, pickRightFork, eat, putLeftFork, putRightFork)：

philosopher 哲学家的编号。
pickLeftFork 和 pickRightFork 表示拿起左边或右边的叉子。
eat 表示吃面。
putLeftFork 和 putRightFork 表示放下左边或右边的叉子。
由于哲学家不是在吃面就是在想着啥时候吃面，所以思考这个方法没有对应的回调。
给你 5 个线程，每个都代表一个哲学家，请你使用类的同一个对象来模拟这个过程。在最后一次调用结束之前，可能会为同一个哲学家多次调用该函数。

**示例1**

```
输入：n = 1
输出：[[4,2,1],[4,1,1],[0,1,1],[2,2,1],[2,1,1],[2,0,3],[2,1,2],[2,2,2],[4,0,3],[4,1,2],[0,2,1],[4,2,2],[3,2,1],[3,1,1],[0,0,3],[0,1,2],[0,2,2],[1,2,1],[1,1,1],[3,0,3],[3,1,2],[3,2,2],[1,0,3],[1,1,2],[1,2,2]]
解释:
n 表示每个哲学家需要进餐的次数。
输出数组描述了叉子的控制和进餐的调用，它的格式如下：
output[i] = [a, b, c] (3个整数)
- a 哲学家编号。
- b 指定叉子：{1 : 左边, 2 : 右边}.
- c 指定行为：{1 : 拿起, 2 : 放下, 3 : 吃面}。
如 [4,2,1] 表示 4 号哲学家拿起了右边的叉子。
```



哲学家就餐应该是操作系统中学到进程同步的时候的必学内容了吧，问题的本质就是解决N个哲学家同时就餐时的死锁问题，一般的解题思路有三种，还有一种和分就类似，学校应该没有讲，如下：

1. 使用and语义，即要么多锁同时被锁定，要么全部不被锁定。
2. 奇偶编号的哲学家加锁顺序不一致即可。
3. 限定就餐人数为N-1，这样死锁的闭环总不成立。
4. 只有一个人拿筷子的顺序和其他人不一样也可以避免一个闭环。

下面就分别来看看四种的写法：



**11.7.1 使用C++ std::lock 实现多锁原子锁定**

这种写法由于CPU资源争用，可能会超时，效率低下

```c++
class DiningPhilosophers {
private:
	mutex mutexs[5];
public:
	DiningPhilosophers() {}

	void wantsToEat(int philosopher,
		function<void()> pickLeftFork,
		function<void()> pickRightFork,
		function<void()> eat,
		function<void()> putLeftFork,
		function<void()> putRightFork) {
		// 让编号为 philosopher 的哲学家就餐，同时锁住他旁边的那个不让其就餐
		int lhs = philosopher;
		int rhs = (philosopher + 1) % 5;

		lock(mutexs[lhs], mutexs[rhs]); // std::lock() 可以同时锁住多个互斥量，防止死锁发生
		lock_guard<mutex> lock_a(mutexs[lhs], adopt_lock);
		lock_guard<mutex> lock_b(mutexs[rhs], adopt_lock);

		pickLeftFork();
		pickRightFork();
		eat();
		putLeftFork();
		putRightFork(); // 在临界区内操作，其实左边右边顺序无关紧要
	}
};
```



**11.7.2 奇偶编号的哲学家加锁顺序不一致**

```c++
class DiningPhilosophers {
private:
	mutex mutexs[5];
	void eating(function<void()> pickLeftFork,
		function<void()> pickRightFork,
		function<void()> eat,
		function<void()> putLeftFork,
		function<void()> putRightFork)
	{
		pickLeftFork();
		pickRightFork();
		eat();
		putLeftFork();
		putRightFork();
	}
public:
	DiningPhilosophers() {}

	void wantsToEat(int philosopher,
		function<void()> pickLeftFork,
		function<void()> pickRightFork,
		function<void()> eat,
		function<void()> putLeftFork,
		function<void()> putRightFork) {
		
		int lhs = philosopher;
		int rhs = (philosopher + 1) % 5;
		if (philosopher & 1) // 奇数
		{
			lock_guard<mutex> lock1(mutexs[lhs]);
			lock_guard<mutex> lock2(mutexs[rhs]);
			eating(pickLeftFork, pickRightFork, eat, putLeftFork, putRightFork);
		}
		else
		{
			lock_guard<mutex> lock2(mutexs[rhs]);
			lock_guard<mutex> lock1(mutexs[lhs]);
			eating(pickLeftFork, pickRightFork, eat, putLeftFork, putRightFork);
		}
	}
};
```



**11.7.3 随意指定一个人和其他人拿筷子的顺序不一样，这样也可以破坏闭环结构**

```c++
class DiningPhilosophers {
private:
	mutex mutexs[5];
	void eating(function<void()> pickLeftFork,
		function<void()> pickRightFork,
		function<void()> eat,
		function<void()> putLeftFork,
		function<void()> putRightFork)
	{
		pickLeftFork();
		pickRightFork();
		eat();
		putLeftFork();
		putRightFork();
	}
public:
	DiningPhilosophers() {}

	void wantsToEat(int philosopher,
		function<void()> pickLeftFork,
		function<void()> pickRightFork,
		function<void()> eat,
		function<void()> putLeftFork,
		function<void()> putRightFork) {
		
		int lhs = philosopher;
		int rhs = (philosopher + 1) % 5;
		if (philosopher == 1) // 随意指定一个数就行
		{
			lock_guard<mutex> lock1(mutexs[lhs]);
			lock_guard<mutex> lock2(mutexs[rhs]);
			eating(pickLeftFork, pickRightFork, eat, putLeftFork, putRightFork);
		}
		else
		{
			lock_guard<mutex> lock2(mutexs[rhs]);
			lock_guard<mutex> lock1(mutexs[lhs]);
			eating(pickLeftFork, pickRightFork, eat, putLeftFork, putRightFork);
		}
	}
};
```