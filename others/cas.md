# **CAS原理**

## **1. CAS示例**

```java
// 类的成员变量
static int data = 0;

// main方法内代码
IntStream.range(0,2).forEach((i) -> {
    new Thread(() -> {
        try {
            Thread.sleep(20);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        IntStream.range(0,100).forEach(y -> {
            data++;
        });
    }).start();
});

try {
    Thread.sleep(2000);
} catch (InterruptedException e) {
    e.printStackTrace();
}

System.out.println(data);
```

上述代码，问题很明显，`data`是类中的成员变量，int类型，即共享的资源。当多个线程同时执行`data++`操作时，结果不等于预期的200。

![img](https://pic2.zhimg.com/80/v2-b4846bc06ccbf426e2911cc48a0e90a9_1440w.webp)

<br>

## **2. 如何保证线程安全**

### **2.1 synchronized关键字**
---

使用`synchronized`关键字，线程内使用同步代码块，由JVM自身的机制来保证线程的安全性。

`synchronized`关键代码:

```java
// 定义类中的Object锁对象
Object lock = new Object();

// synchronized 同步块()中使用lock对象锁定资源
IntStream.range(0,100).forEach(y -> {
    synchronized (lock.getClass()) {
        data++;
    }
})
```

![img](https://pic1.zhimg.com/80/v2-c86167a3a35cf246021245959d1a42a8_1440w.webp)

<br>

### **2.2 使用Lock锁**
---

高并发场景下，使用`Lock`锁要比使用`synchronized`关键字，在性能上得到极大的提高。因为`Lock`底层是通过 AQS + CAS 机制来实现的。

使用`Lock`的关键代码:

```java
// 类中定义成员变量
Lock lock = new ReentrantLock();

// 执行 lock() 方法加锁，执行 unlock() 方法解锁
IntStream.range(0, 100).forEach(y -> {
        lock.lock();
        data++;
        lock.unlock();
});
```

![img](https://pic4.zhimg.com/80/v2-fb77ac8342fad54f4795c437a3a7febf_1440w.webp)

<br>

### **2.3 使用原子变量**
---

`synchronized`的使用在 JDK1.6 版本以后做了很多优化，如果并发量不大，相比`Lock`更为安全，性能也能接受，因其得益于 JVM 底层机制来保障，自动释放锁，无需硬编码方式释放锁。而使用`Lock`方式，一旦`unlock()`方法使用不规范，可能导致死锁。

对于有原子类实现的数据结构，建议直接采用原子类来实现并发读写，因为其底层是通过CAS来实现的，性能更高。

对于例子中的`data`数据，可以使用`AtomicInteger`工具类来实现代码:

```java
// 类中成员变量定义原子类
AtomicInteger atomicData = new AtomicInteger();

// 代码中原子类的使用方式
IntStream.range(0, 2).forEach((i) -> {
    new Thread(() -> {
            try {
                    Thread.sleep(20);
            } catch (InterruptedException e) {
                    e.printStackTrace();
            }
            IntStream.range(0, 100).forEach(y -> {
                  // 原子类自增
                    atomicData.incrementAndGet();
            });
    }).start();
});

try {
        Thread.sleep(2000);
} catch (InterruptedException e) {
        e.printStackTrace();
}

// 通过 get () 方法获取结果
System.out.println(atomicData.get());
```

![img](https://pic2.zhimg.com/80/v2-c34c63d9ac7c6ed4c5ab5363c332eb81_1440w.webp)

<br>

### **2.4 使用LongAdder原子类**
---

`LongAdder`原子类在 JDK1.8 中新增的类， 跟方案三中提到的`AtomicInteger`类似，都是在`java.util.concurrent.atomic`并发包下的。

`LongAdder`适合于高并发场景下，特别是写大于读的场景，相较于`AtomicInteger`、`AtomicLong`性能更好，代价是消耗更多的空间，以空间换时间。

使用`LongAdder`工具类实现代码:

```java
// 类中成员变量定义的LongAdder
LongAdder longAdderData = new LongAdder();

// 代码中原子类的使用方式
IntStream.range(0, 2).forEach((i) -> {
        new Thread(() -> {
                try {
                        Thread.sleep(20);
                } catch (InterruptedException e) {
                        e.printStackTrace();
                }
                IntStream.range(0, 100).forEach(y -> {
                      // 使用 increment() 方法自增
                        longAdderData.increment();
                });
        }).start();
});

try {
        Thread.sleep(2000);
} catch (InterruptedException e) {
        e.printStackTrace();
}
// 使用 sum() 获取结果
System.out.println(longAdderData.sum());
```

![img](https://pic1.zhimg.com/80/v2-1535e19eafecdfcd98054712de0f9564_1440w.webp)

但是，如果使用了`LongAdder`原子类，当然其底层也是基于 CAS 机制实现的。`LongAdder`内部维护了`base`变量和`Cell[]`数组，当多线程并发写的情况下，各个线程都在写入自己的`Cell`中，`LongAdder`操作后返回的是个近似准确的值，最终也会返回一个准确的值。

换句话说，使用了`LongAdder`后获取的结果并不是实时的，对实时性要求高的还是建议使用其他的原子类，如`AtomicInteger`等。

<br>

## **3. CAS原理剖析**

CAS （compareAndSwap）是一种无锁原子算法，映射到操作系统就是一条CPU的原子指令，其作用是让CPU先进行比较两个值是否相等，然后原子地更新某个位置的值，其实现方式是基于硬件平台的汇编指令，在intel的CPU中，使用的是`cmpxchg`指令，就是说CAS是靠硬件实现的，从而在硬件层面提升效率。

执行过程是这样：它包含 3 个参数 CAS（V，E，N），V表示要更新变量的值，E表示预期值，N表示新值。仅当 V值等于E值时，才会将V的值设为N，如果V值和E值不同，则说明已经有其他线程完成更新，则当前线程则什么都不做，最后CAS 返回当前V的真实值。

当多个线程同时使用CAS 操作一个变量时，最多只有一个会胜出，并成功更新，其余均会失败。失败的线程不会挂起，仅是被告知失败，并且允许再次尝试（自旋），当然也允许实现的线程放弃操作。基于这样的原理，CAS 操作即使没有锁，也可以避免其他线程对当前线程的干扰。

与锁相比，使用CAS会使程序看起来更加复杂一些，但是使用无锁的方式完全没有锁竞争带来的线程间频繁调度的开销和阻塞，它对死锁问题天生免疫，因此他要比基于锁的方式拥有更优越的性能。

简单的说，CAS 需要你额外给出一个期望值，也就是你认为这个变量现在应该是什么样子的。如果变量不是你想象的那样，说明它已经被别人修改过了。你就需要重新读取，再次尝试修改就好了。

推荐阅读: https://blog.csdn.net/qq_42370146/article/details/105559575

<br>