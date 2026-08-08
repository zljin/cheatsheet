---
title: Java并发编程
date: 2022-05-22 08:00:45
tags:
  - TechBase
categories: Java
---

> 多线程编写的三大核心原则：**原子性、可见性、有序性**。  
> 理解这些概念是编写安全并发程序的基础。

---

## 一、基础概念

### 1.1 进程与线程
- **进程**：操作系统进行资源分配和调度的基本单位，是程序的一次执行过程。
- **线程**：CPU 调度的最小单位，一个进程可以包含多个线程，它们共享进程的内存资源（堆、方法区），但拥有独立的栈空间。

### 1.2 并发与并行
- **并发**：同一时间段内，单核 CPU 通过时间片轮转交替执行多个任务，宏观上看起来像是同时进行。
- **并行**：多核 CPU 在同一时刻真正同时执行多个任务。

### 1.3 阻塞与非阻塞
描述调用方在等待结果时的线程状态：
- **阻塞**：调用方一直等待，直到结果返回才继续往下执行。
- **非阻塞**：调用方发出请求后立即返回，可以先去干别的事情，稍后再来检查结果或通过回调获取。

### 1.4 同步与异步
描述消息通信机制：
- **同步**：调用方主动等待结果，直到被调用方完成处理并返回。
- **异步**：调用方发出请求后立即返回，被调用方处理完成后通过回调、事件等方式通知调用方。

---

## 二、创建线程的方式

> 后续实际开发中统一推荐使用 `CompletableFuture` 进行异步编排，这里先了解基础创建方式。

```java
/**
 * 创建线程的三种方式：
 * 1. 继承 Thread 类
 * 2. 实现 Runnable 接口
 * 3. 实现 Callable 接口 + FutureTask
 *
 * Runnable 与 Callable 的区别：
 * - Runnable 无返回值，不能抛出受检异常；
 * - Callable 有返回值，支持泛型，可以抛出受检异常。
 * - 结合 FutureTask 可以获取结果、取消任务、判断是否完成。
 */
public class CreateThread {

    public static void main(String[] args) {
        Callable<Integer> task = new Callable<Integer>() {
            @Override
            public Integer call() throws Exception {
                return new Random().nextInt();
            }
        };
        // 直接通过线程池提交 Callable，返回 Future
        Future<Integer> future = ThreadPoolManager.THREAD_POOL_EXECUTOR.submit(task);
        try {
            System.out.println(future.get());
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        } finally {
            ThreadPoolManager.THREAD_POOL_EXECUTOR.shutdown();
        }
    }

    // FutureTask 的使用演示
    public static void main1(String[] args) {
        Callable<Integer> task = new Callable<Integer>() {
            @Override
            public Integer call() throws Exception {
                return new Random().nextInt();
            }
        };
        FutureTask<Integer> futureTask = new FutureTask<>(task);
        // 可以交给 Thread 或线程池执行
        new Thread(futureTask).start();
        // ThreadPoolManager.THREAD_POOL_EXECUTOR.submit(task);

        try {
            System.out.println("task 运行结果：" + futureTask.get());
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }

    // get() 阻塞直到任务完成，异常在 get() 时才会抛出
    public static void main2(String[] args) {
        Callable<Integer> task = new Callable<Integer>() {
            @Override
            public Integer call() throws Exception {
                throw new IllegalArgumentException("Callable 抛出异常");
            }
        };
        Future<Integer> future = ThreadPoolManager.THREAD_POOL_EXECUTOR.submit(task);
        try {
            for (int i = 0; i < 5; i++) {
                System.out.println(i);
                Thread.sleep(500);
            }
            System.out.println("任务完成？ " + future.isDone());
            future.get(); // 这里才会抛出 ExecutionException
        } catch (InterruptedException e) {
            System.out.println("InterruptedException 异常");
        } catch (ExecutionException e) {
            System.out.println("ExecutionException 异常，原因：" + e.getCause());
        } finally {
            ThreadPoolManager.THREAD_POOL_EXECUTOR.shutdown();
        }
    }
}
```

---

## 三、Happens-Before 与 As-If-Serial

- **指令重排序**：编译器和处理器为了优化性能，可能会调整指令的执行顺序。
- **as-if-serial**：保证在**单线程**环境下，无论怎么重排序，程序的最终执行结果不会改变。
- **happens-before**：定义**多线程**环境下操作之间的可见性规则。如果操作 A happens-before 操作 B，那么 A 的结果对 B 是可见的（强调逻辑顺序，不要求物理时间先后）。

```java
// 单线程下：
int a = 2;     // A
int b = 3;     // B
int c = a * b; // C
// A 和 B 之间没有数据依赖，可以重排序
// C 依赖 A、B，必须排在它们后面
// as-if-serial 保证 c 的结果永远是 6
```

### volatile 的作用
- 保证**可见性**：一个线程修改 volatile 变量后，其他线程立即可见。
- 禁止指令重排序：通过内存屏障，保证特定代码的执行顺序。
- 适用于一写多读的场景，但不能保证复合操作（如 i++）的原子性。

经典应用：**双重检查锁定（DCL）单例模式**

```java
public class SafeSingleton {
    private static volatile SafeSingleton instance; // 必须使用 volatile 禁止重排序

    public static SafeSingleton getInstance() {
        if (instance == null) {
            synchronized (SafeSingleton.class) {
                if (instance == null) {
                    // instance = new SafeSingleton() 分三步：
                    // 1. 分配内存空间
                    // 2. 初始化对象（执行构造方法）
                    // 3. 将 instance 指向分配的内存地址
                    // 若不加 volatile，2 和 3 可能重排序，导致其他线程拿到未初始化完毕的对象
                    instance = new SafeSingleton();
                }
            }
        }
        return instance;
    }
}
```

---

## 四、线程生命周期

![线程状态转换图](https://cdn.jsdelivr.net/gh/zljin/img_bed/threadlifecyle.jpg?raw=true)

Java 线程共有 6 种状态：`NEW`、`RUNNABLE`、`BLOCKED`、`WAITING`、`TIMED_WAITING`、`TERMINATED`。上图清晰展示了它们之间的转换关系。

---

## 五、守护线程

- 守护线程是一种后台服务线程，例如 JVM 的垃圾回收线程。
- 当所有非守护线程结束时，JVM 会直接退出，不会等待守护线程执行完毕，守护线程会被强制终止。
- 设置方法：`thread.setDaemon(true)`，且必须在 `start()` 之前调用。

```java
Thread thread = new Thread(() -> {
    while (true) {
        // 监控、日志等后台任务
    }
});
thread.setDaemon(true);
thread.start();
```

---

## 六、死锁

多个线程相互持有对方需要的锁资源，导致永久等待的现象。

### 6.1 出现场景及解决思路
- **场景**：线程 A 持有锁 L1 请求锁 L2，线程 B 持有锁 L2 请求锁 L1。
- **解决方案**：
  1. **全局锁排序**：所有线程按同一顺序获取锁（例如永远先获取 L1 再获取 L2）。
  2. **设置锁超时**：使用 `ReentrantLock.tryLock(timeout)`，超时则放弃并回退，避免无限等待。
  3. 应用层面也可用异步消息解耦、缓存减少锁竞争等手段。

### 6.2 死锁监控
- `jps` 查看 Java 进程 ID
- `jstack pid` 导出线程堆栈，分析死锁信息
- MySQL 中可用 `SHOW ENGINE INNODB STATUS` 查看事务锁信息

### 6.3 代码示例

**按序加锁避免死锁**

```java
public class DeadLockAvoid {
    private static final Object lockFirst = new Object();
    private static final Object lockSecond = new Object();

    public static void main(String[] args) {
        new Thread(() -> {
            synchronized (lockFirst) {
                System.out.println(Thread.currentThread().getName() + " 获取到 lockFirst");
                try { Thread.sleep(100); } catch (InterruptedException e) {}
                synchronized (lockSecond) {
                    System.out.println(Thread.currentThread().getName() + " 获取到 lockSecond");
                }
            }
        }, "线程1").start();

        new Thread(() -> {
            synchronized (lockFirst) { // 这里也先请求 lockFirst，避免死锁
                System.out.println(Thread.currentThread().getName() + " 获取到 lockFirst");
                try { Thread.sleep(100); } catch (InterruptedException e) {}
                synchronized (lockSecond) {
                    System.out.println(Thread.currentThread().getName() + " 获取到 lockSecond");
                }
            }
        }, "线程2").start();
    }
}
```

**使用 tryLock 设置超时**

```java
public class DeadLockTimeout {
    private static final Lock lockA = new ReentrantLock();
    private static final Lock lockB = new ReentrantLock();

    public static void main(String[] args) {
        new Thread(() -> tryLockOrder("线程1", lockA, lockB)).start();
        new Thread(() -> tryLockOrder("线程2", lockB, lockA)).start();
    }

    private static void tryLockOrder(String name, Lock first, Lock second) {
        while (true) {
            boolean gotFirst = false, gotSecond = false;
            try {
                gotFirst = first.tryLock(100, TimeUnit.MILLISECONDS);
                if (gotFirst) {
                    System.out.println(name + " 获取到第一把锁");
                    gotSecond = second.tryLock(100, TimeUnit.MILLISECONDS);
                    if (gotSecond) {
                        System.out.println(name + " 获取到第二把锁，业务处理...");
                        return;
                    }
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                if (gotSecond) second.unlock();
                if (gotFirst) first.unlock();
            }
        }
    }
}
```

---

## 七、ThreadLocal

### 7.1 基本概念
`ThreadLocal` 为每个线程提供独立的变量副本，线程之间互不干扰，以空间换时间的方式避免共享变量带来的并发问题。

### 7.2 典型应用
- Spring 事务管理中使用 `ThreadLocal` 保存当前线程的数据库连接，保证事务的隔离性。
- 在 Web 应用中，每次请求对应一个线程，可以用 `ThreadLocal` 传递用户上下文（如登录用户信息），避免方法层层传参。

### 7.3 注意事项
1. 当线程数量很大时，大量 `ThreadLocal` 实例会占用较多内存，需评估是否需要。
2. 优先使用框架提供的支持（如 Spring 的 `RequestContextHolder`），而不是自己随意创建。
3. `ThreadLocal` 内部使用 `WeakReference` 包装 key，但 value 是强引用，如果不调用 `remove()` 可能导致内存泄漏（线程池环境下线程复用，value 一直无法回收）。

### 7.4 父子线程共享变量
默认 `ThreadLocal` 不能将变量传递给子线程。如需传递，可使用 `InheritableThreadLocal`，它在创建子线程时会拷贝父线程的 `InheritableThreadLocal` 值。但在线程池场景下因线程复用，拷贝只在创建时发生，可能带来不一致问题，此时可考虑阿里的 `TransmittableThreadLocal` 组件。

```java
public class InheritableThreadLocalDemo {
    private static final InheritableThreadLocal<String> context = new InheritableThreadLocal<>();

    public static void main(String[] args) {
        context.set("主线程数据");
        new Thread(() -> {
            // 可以获取到父线程设置的值
            System.out.println("子线程获取：" + context.get());
        }).start();
    }
}
```

---

## 八、线程池

### 8.1 线程池的作用
- 降低资源消耗：复用已创建的线程，减少线程创建/销毁的开销。
- 提高响应速度：任务到达时无需等待线程创建即可执行。
- 便于集中管理：统一分配、调优和监控。

### 8.2 线程池参数配置
- **CPU 密集型任务**：线程数 ≈ CPU 核心数 + 1
- **IO 密集型任务**：线程数 ≈ CPU 核心数 * 2（也需结合具体 IO 等待时间调整）

### 8.3 自定义线程池示例

```java
public class ThreadPoolManager {
    private ThreadPoolManager() {}

    public static final ThreadPoolExecutor THREAD_POOL_EXECUTOR;

    private static final int CORE_POOL_SIZE = 2;
    private static final int MAX_POOL_SIZE = 3;
    private static final int QUEUE_CAPACITY = 5;
    private static final int KEEP_ALIVE_TIME = 60; // 秒

    static {
        THREAD_POOL_EXECUTOR = new ThreadPoolExecutor(
                CORE_POOL_SIZE,
                MAX_POOL_SIZE,
                KEEP_ALIVE_TIME,
                TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(QUEUE_CAPACITY),   // 有界队列，防止任务堆积
                new ThreadPoolExecutor.CallerRunsPolicy()   // 拒绝策略：交给调用线程执行
        );
    }

    public static void main(String[] args) {
        for (int i = 0; i < 9; i++) {
            THREAD_POOL_EXECUTOR.execute(() -> {
                System.out.println(Thread.currentThread().getName() + " running");
            });
        }
        THREAD_POOL_EXECUTOR.shutdown(); // 有序关闭，已提交任务会执行完
        // executorService.shutdownNow(); // 立刻关闭，返回未执行的任务列表
    }
}
```

**工作队列选择**：
- `ArrayBlockingQueue`：有界，防止资源耗尽。
- `LinkedBlockingQueue`：无界（默认容量 `Integer.MAX_VALUE`），容易造成任务堆积。
- `SynchronousQueue`：不存储任务，直接交接给线程，若无空闲线程则新建，可能造成线程数暴涨。

**四大拒绝策略（队列满且线程数达最大时）**：
- `AbortPolicy`（默认）：抛 `RejectedExecutionException`。
- `CallerRunsPolicy`：将任务回退给提交任务的线程执行。
- `DiscardPolicy`：直接丢弃任务，不抛异常。
- `DiscardOldestPolicy`：丢弃队首最老的任务，尝试重新提交。

### 8.4 submit() 与 execute() 的区别

| 特性         | `execute()`                  | `submit()`                                      |
|--------------|------------------------------|-------------------------------------------------|
| 参数         | 只接受 `Runnable`            | 接受 `Runnable` 和 `Callable`                    |
| 返回值       | `void`                       | `Future<?>`，可获取结果、取消任务等              |
| 异常处理     | 在线程内部抛出，线程可能终止 | 异常被封装在 `Future` 里，调用 `get()` 时才抛出 |

---

## 九、CompletableFuture

> 参考：[Java CompletableFuture 详解](https://juejin.cn/post/6970558076642394142)

`CompletableFuture` 提供了强大的异步编排能力，支持任务组合、异常处理、超时控制等。以下综合示例演示了常见用法。

```java
/**
 * CompletableFuture 综合示例：
 * 模拟查询用户信息、订单、积分，并进行组合计算，最后发送通知。
 */
public class CompletableFutureDemo {
    // ---------- 模拟服务 ----------
    static class UserService {
        public User getUserInfo(String userId) {
            sleep(200);
            if (Math.random() < 0.2) throw new RuntimeException("用户服务异常");
            return new User(userId, "用户" + userId, 100);
        }
    }

    static class OrderService {
        public List<Order> getUserOrders(String userId) {
            sleep(300);
            return Arrays.asList(new Order("ORD001", userId, 299.99, "已完成"),
                                 new Order("ORD002", userId, 599.99, "待发货"));
        }
    }

    static class ScoreService {
        public int calculateScore(List<Order> orders) {
            sleep(150);
            return orders.stream().mapToInt(o -> (int)(o.amount / 100) * 10).sum();
        }
    }

    static class NotificationService {
        public void send(String msg) {
            sleep(100);
            System.out.println("【通知】" + msg);
        }
    }

    static void sleep(int ms) {
        try { Thread.sleep(ms); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }

    // ---------- 主流程 ----------
    public static void main(String[] args) {
        ExecutorService pool = Executors.newFixedThreadPool(4);
        String userId = "U1001";

        // 1. 异步获取用户信息，异常时提供默认值
        CompletableFuture<User> userFuture = CompletableFuture
                .supplyAsync(() -> new UserService().getUserInfo(userId), pool)
                .exceptionally(ex -> {
                    System.err.println("获取用户失败，使用默认用户: " + ex.getMessage());
                    return new User(userId, "默认用户", 0);
                })
                .whenComplete((user, ex) -> {
                    if (ex == null) System.out.println("用户信息获取完成: " + user.name);
                });

        // 2. 异步获取订单，2秒超时则返回空列表
        CompletableFuture<List<Order>> ordersFuture = CompletableFuture
                .supplyAsync(() -> new OrderService().getUserOrders(userId), pool)
                .completeOnTimeout(Collections.emptyList(), 2, TimeUnit.SECONDS);

        // 3. 基于用户信息再异步计算基础积分（链式依赖）
        CompletableFuture<Integer> baseScoreFuture = userFuture
                .thenCompose(user -> CompletableFuture.supplyAsync(() -> user.score, pool));

        // 4. 组合订单和积分，计算总积分
        CompletableFuture<Integer> totalScoreFuture = ordersFuture
                .thenCombine(baseScoreFuture, (orders, base) -> base + new ScoreService().calculateScore(orders));

        // 5. 组合用户、订单、积分生成最终报告
        CompletableFuture<String> reportFuture = userFuture
                .thenCombine(ordersFuture, (user, orders) -> "用户: " + user.name + ", 订单数: " + orders.size())
                .thenCombine(totalScoreFuture, (info, score) -> info + ", 总积分: " + score);

        // 6. 独立的异步发送通知
        CompletableFuture<Void> notificationFuture = CompletableFuture
                .runAsync(() -> new NotificationService().send("开始处理" + userId + "的数据"), pool);

        // 7. 等待所有任务完成
        CompletableFuture<Void> all = CompletableFuture.allOf(userFuture, ordersFuture, totalScoreFuture, reportFuture, notificationFuture);
        // anyOf 演示：两个任务谁先完成就用谁的结果
        CompletableFuture<Object> any = CompletableFuture.anyOf(
                CompletableFuture.supplyAsync(() -> { sleep(400); return "任务1"; }, pool),
                CompletableFuture.supplyAsync(() -> { sleep(200); return "任务2"; }, pool)
        );
        any.thenAccept(result -> System.out.println("第一个完成: " + result));

        // 输出最终结果
        System.out.println("\n=== 最终报告 ===");
        System.out.println(reportFuture.join());
        all.thenRun(() -> System.out.println("所有任务执行完毕，执行清理操作。"));

        pool.shutdown();
    }
}
```

---

## 十、AQS（AbstractQueuedSynchronizer）

AQS 是 JUC（java.util.concurrent）包的基石，提供了一套通用的同步框架。

### 10.1 核心设计
- **状态管理**：用 `volatile int state` 表示同步状态，通过 CAS 操作安全修改，避免重量级锁。
- **等待队列**：内部维护一个 CLH 变体队列（FIFO），管理获取同步状态失败的线程。
- **模板方法模式**：子类只需实现 `tryAcquire`/`tryRelease`（独占模式）或 `tryAcquireShared`/`tryReleaseShared`（共享模式），AQS 负责排队、阻塞、唤醒等通用逻辑。
- **支持公平/非公平**：通过构造器参数或子类实现决定。

### 10.2 CAS（Compare And Swap）
乐观锁的核心操作，包含三个操作数：内存值 V、期望原值 A、新值 B。仅当 V == A 时，才将 V 更新为 B。CAS 可解决部分并发问题，但存在 ABA 问题，可通过版本号（`AtomicStampedReference`）解决。

### 10.3 基于 AQS 实现互斥锁

```java
public class SimpleMutex extends AbstractQueuedSynchronizer {
    @Override
    protected boolean tryAcquire(int arg) {
        if (compareAndSetState(0, 1)) {
            setExclusiveOwnerThread(Thread.currentThread());
            return true;
        }
        return false;
    }

    @Override
    protected boolean tryRelease(int arg) {
        if (getState() == 0) throw new IllegalMonitorStateException();
        setExclusiveOwnerThread(null);
        setState(0);
        return true;
    }

    public void lock()   { acquire(1); }
    public void unlock() { release(1); }
}
```

### 10.4 基于 AQS 实现简单信号量

```java
public class SimpleSemaphore extends AbstractQueuedSynchronizer {
    public SimpleSemaphore(int permits) {
        setState(permits);
    }

    @Override
    protected int tryAcquireShared(int acquires) {
        for (;;) {
            int available = getState();
            int remaining = available - acquires;
            if (remaining < 0 || compareAndSetState(available, remaining))
                return remaining;
        }
    }

    @Override
    protected boolean tryReleaseShared(int releases) {
        for (;;) {
            int current = getState();
            int next = current + releases;
            if (compareAndSetState(current, next))
                return true;
        }
    }

    public void acquire() { acquireShared(1); }
    public void release() { releaseShared(1); }
}
```

---

## 十一、线程协作与流程控制

### 11.1 wait/notify（基于对象锁）

```java
public class WaitNotifyDemo {
    private static final Object lock = new Object();
    private static boolean flag = false;

    public static void main(String[] args) throws InterruptedException {
        Thread waitThread = new Thread(() -> {
            synchronized (lock) {
                while (!flag) {  // 用 while 防止虚假唤醒
                    try { lock.wait(); } catch (InterruptedException e) { e.printStackTrace(); }
                }
                System.out.println("等待线程被唤醒");
            }
        });

        Thread notifyThread = new Thread(() -> {
            synchronized (lock) {
                try { Thread.sleep(2000); } catch (InterruptedException e) { e.printStackTrace(); }
                flag = true;
                lock.notify(); // 或 notifyAll()
                System.out.println("通知已发出");
            }
        });

        waitThread.start();
        Thread.sleep(500);
        notifyThread.start();
    }
}
```

### 11.2 Lock + Condition

```java
public class ConditionDemo {
    private static final ReentrantLock lock = new ReentrantLock();
    private static final Condition condition = lock.newCondition();
    private static boolean ready = false;

    public static void main(String[] args) throws InterruptedException {
        new Thread(() -> {
            lock.lock();
            try {
                while (!ready) { condition.await(); }
                System.out.println("条件满足，继续执行");
            } catch (InterruptedException e) { e.printStackTrace(); }
            finally { lock.unlock(); }
        }).start();

        new Thread(() -> {
            lock.lock();
            try {
                Thread.sleep(2000);
                ready = true;
                condition.signal();
                System.out.println("条件已通知");
            } catch (InterruptedException e) { e.printStackTrace(); }
            finally { lock.unlock(); }
        }).start();
    }
}
```

### 11.3 CountDownLatch（倒计时门闩）
等待一组线程完成后再继续，一次性使用。

```java
CountDownLatch latch = new CountDownLatch(3);
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        // do work...
        latch.countDown(); // 计数减1
    }).start();
}
latch.await(); // 等待计数归零
```

### 11.4 CyclicBarrier（循环栅栏）
让一组线程互相等待，全部到达后一起继续，可重复使用。

```java
CyclicBarrier barrier = new CyclicBarrier(3, () -> System.out.println("所有选手就位，比赛开始！"));
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        try {
            System.out.println(Thread.currentThread().getName() + " 到达等待点");
            barrier.await(); // 等待其他线程
            // 继续执行...
        } catch (Exception e) { e.printStackTrace(); }
    }).start();
}
```

### 11.5 Semaphore（信号量）
控制同时访问特定资源的线程数量。

```java
// 停车场模拟：只有3个车位，10辆车竞争
Semaphore semaphore = new Semaphore(3, true); // 公平模式
for (int i = 0; i < 10; i++) {
    new Thread(() -> {
        try {
            semaphore.acquire();
            System.out.println(Thread.currentThread().getName() + " 停车");
            Thread.sleep(2000);
        } catch (InterruptedException e) { e.printStackTrace(); }
        finally {
            semaphore.release();
            System.out.println(Thread.currentThread().getName() + " 离开");
        }
    }).start();
}
```

**利用 Semaphore 实现线程顺序执行**：

```java
public class ThreadOrder {
    private static final Semaphore s1 = new Semaphore(0);
    private static final Semaphore s2 = new Semaphore(0);

    public static void main(String[] args) {
        new Thread(() -> { System.out.println("线程1"); s1.release(); }).start();
        new Thread(() -> {
            try { s1.acquire(); } catch (InterruptedException e) {}
            System.out.println("线程2");
            s2.release();
        }).start();
        new Thread(() -> {
            try { s2.acquire(); } catch (InterruptedException e) {}
            System.out.println("线程3");
        }).start();
    }
}
```

### 11.6 Exchanger
用于两个线程之间交换数据，双方都执行到 `exchange()` 时完成互换。

```java
Exchanger<String> exchanger = new Exchanger<>();
new Thread(() -> {
    String data = "来自线程A的数据";
    String received = exchanger.exchange(data);
    System.out.println("A 收到：" + received);
}).start();
new Thread(() -> {
    String data = "来自线程B的数据";
    String received = exchanger.exchange(data);
    System.out.println("B 收到：" + received);
}).start();
```

---

## 十二、并发容器与工具

- `ConcurrentHashMap`：线程安全的 Map，分段锁/CAS，并发度高。
- `CopyOnWriteArrayList`：写时复制数组，适合读多写少，最终一致性。
- `AtomicInteger`：基于 CAS 的原子操作类，保证整数运算的原子性。
- `BlockingQueue`：阻塞队列，常用于生产者-消费者模式。

### 生产者-消费者示例

```java
public class BlockingQueueP2C {
    static class Factory {
        private final BlockingQueue<String> queue = new ArrayBlockingQueue<>(3);
        private final int total;
        private volatile boolean producerFinished;

        public Factory(int total) { this.total = total; }

        public void produce() {
            try {
                for (int i = 0; i < total; i++) {
                    queue.put("product" + i);
                    System.out.println("生产 product" + i);
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                producerFinished = true;
            }
        }

        public void consume() {
            try {
                while (!queue.isEmpty() || !producerFinished) {
                    String item = queue.take();
                    System.out.println("消费 " + item);
                    Thread.sleep(2000);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }

    public static void main(String[] args) {
        Factory factory = new Factory(10);
        new Thread(factory::produce).start();
        new Thread(factory::consume).start();
    }
}
```

### 两个线程交替打印 FooBar（BlockingQueue 实现）

```java
public class FooBarBlockingQueue {
    private BlockingQueue<Integer> foo = new LinkedBlockingQueue<>(1);
    private BlockingQueue<Integer> bar = new LinkedBlockingQueue<>(1);
    private int times;

    public FooBarBlockingQueue(int times) { this.times = times; }

    public void printFoo(Runnable printFoo) throws Exception {
        for (int i = 0; i < times; i++) {
            foo.put(i);
            printFoo.run();
            bar.put(i);
        }
    }

    public void printBar(Runnable printBar) throws Exception {
        for (int i = 0; i < times; i++) {
            bar.take();
            printBar.run();
            foo.take();
        }
    }

    public static void main(String[] args) {
        FooBarBlockingQueue fb = new FooBarBlockingQueue(10);
        new Thread(() -> { try { fb.printFoo(() -> System.out.print("foo")); } catch (Exception e) { e.printStackTrace(); } }).start();
        new Thread(() -> { try { fb.printBar(() -> System.out.print("bar")); } catch (Exception e) { e.printStackTrace(); } }).start();
    }
}
```

---

## 十三、锁的分类与特性总结

| 分类方式 | 锁类型 | 特点 |
|----------|--------|------|
| 乐观/悲观 | 悲观锁（synchronized, ReentrantLock） | 认为并发冲突多，每次操作都加锁 |
|           | 乐观锁（CAS, AtomicInteger） | 认为冲突少，先尝试操作，失败再重试 |
| 可重入性 | 可重入锁（synchronized, ReentrantLock） | 同一个线程可多次获取同一把锁 |
| 共享/排他 | 共享锁（ReadLock） | 多个线程可同时持有读锁 |
|           | 排他锁（WriteLock） | 写锁独占，其他线程无法读写 |
| 自旋/阻塞 | 自旋锁 | 获取不到锁时循环尝试，不放弃CPU，适合锁持有时间短的场景 |
|           | 阻塞锁 | 获取不到锁时线程挂起，释放CPU，适合锁持有时间较长的场景 |
| 锁升级 | synchronized | 无锁 → 偏向锁 → 轻量级锁 → 重量级锁，不可降级 |
| 锁降级 | ReentrantReadWriteLock | 写锁可以降级为读锁（获取写锁 → 获取读锁 → 释放写锁） |

**锁降级示例**：

```java
ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
rwLock.writeLock().lock();
try {
    // 执行业务写操作
    rwLock.readLock().lock(); // 获取读锁（准备降级）
} finally {
    rwLock.writeLock().unlock(); // 释放写锁，此时仍持有读锁
}
// 后续可以继续使用读锁...
rwLock.readLock().unlock();
```

---

> 掌握这些并发编程知识，能够帮助编写高效、安全的多线程程序。实际应用中应结合业务场景选择合适的并发策略和工具类。