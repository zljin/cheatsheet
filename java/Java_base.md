---
title: Java基础
date: 2019-01-22 08:00:45
tags:
  - TechBase
categories: Java
---

## 基础语法

### 数据类型

Java 数据类型分为 **基本数据类型**、**包装类型** 和 **引用类型**。

**基本数据类型**：  
`byte`、`char`、`boolean`、`short`、`int`、`long`、`float`、`double`

**包装类型**  
将基本类型封装成类（如 `int` → `Integer`），从而获得面向对象的特性（泛型、集合、工具方法等），并支持自动装箱与拆箱。

**引用类型**  
类、接口、数组等，例如 `String`、自定义对象。

```java
/**
 * BigDecimal 比较：equals 检查 scale，compareTo 只比较数值
 * Integer 缓存：-128~127 内复用对象，== 为 true；超出范围则新建对象
 */
public class NumberTest {
    public static void main(String[] args) {
        BigDecimal a = new BigDecimal("1.0");
        BigDecimal b = new BigDecimal("1.00");
        System.out.println(a.equals(b));         // false
        System.out.println(a.compareTo(b) == 0); // true

        Integer c = 1000;
        Integer d = 1000;
        System.out.println(c == d);      // false，超出缓存范围
        System.out.println(c.equals(d)); // true
    }

    //UTF-8 编码下，不同字符占用的字节数不同
    public static void main1(String[] args) throws Exception {
        System.out.println(getUTF8BytesLength("A"));// 1 字节
        System.out.println(getUTF8BytesLength("中"));// 3 字节
    }
    public static int getUTF8BytesLength(String text) throws UnsupportedEncodingException {
        return text.getBytes("UTF-8").length;
    }
}
```

### 关键字

Java 中具有特殊用途的保留单词。

| 类别         | 关键字 / 说明 |
|--------------|---------------|
| 权限修饰符   | `public`（公共）<br>`protected`（同包 + 子类）<br>`default`（同包，无关键字）<br>`private`（本类） |
| `static`     | 1. 随着类的加载而加载，优先于对象存在<br>2. 被所有对象共享<br>3. 静态上下文中不能直接访问非静态成员 |
| `final`      | 1. 修饰类 → 不可继承<br>2. 修饰方法 → 不可重写<br>3. 修饰基本类型变量 → 值不可变<br>4. 修饰引用类型变量 → 引用地址不可变（对象内容可改变） |

### 标识符与运算符

- **标识符**：给变量、类、方法等命名的符号。
- **运算符**：算术、赋值、比较、逻辑、位运算等。

### 流程控制

支持分支（`if-else`、`switch`）和循环（`for`、`while`、`do-while`）。  

---

## 面向对象

- **类**：具有相同特征（属性）和行为（方法）的抽象描述。
- **对象**：通过类创建的具体实例。

### 三大特征

1. **封装**  
   隐藏内部实现细节，仅暴露必要的访问接口，提高安全性和可维护性。

2. **继承**  
   子类复用父类的属性和方法，并可重写或扩展。Java 支持单继承，接口可多实现。

3. **多态**  
   父类引用指向子类对象，同一操作作用于不同对象时表现出不同行为。  
   - 成员方法：编译看左边（父类），运行看右边（子类）——动态绑定。  
   - 成员变量 / 静态方法：编译看左边，运行也看左边——静态绑定。

### 方法重载与重写

|          | 重载 (Overload)          | 重写 (Override)                  |
|----------|--------------------------|----------------------------------|
| 位置     | 同一个类中               | 子类中                           |
| 规则     | 方法名相同，参数列表不同 | 方法名相同，返回类型可协变     |
| 限制     | 与返回值、修饰符无关     | 访问权限不能更低，异常不能更宽   |
| 注意     | -                        | 构造方法、静态方法不能被重写     |

### 抽象类与接口

- **抽象类**  
  包含抽象方法的类，不能实例化，只能单继承。常用于模板设计。
- **接口**  
  更纯粹的抽象，支持多实现。用于约束类的行为规范。

### 构造方法

用于创建对象并初始化成员变量。  
**类的初始化顺序**：  
静态变量/块 → 实例变量/普通块 → 构造方法。

### 参数传递

**Java 中只有值传递**。  
- 基本类型：传递数值的副本。  
- 引用类型：传递引用地址的副本（指向同一对象）。  
- 包装类型：因自动装箱拆箱，行为与基本类型类似。

---

## Object 类

- `==`：基本类型比较**值**；引用类型比较**地址**（是否为同一对象）。  
- `equals()`：默认实现与 `==` 相同，需重写来比较对象**内容**。  
- `hashCode()`：默认返回对象内存地址。**Java 约定**：若 `equals()` 相等，则 `hashCode()` 必须相等。重写 `equals` 必须同时重写 `hashCode`，否则在 `HashMap`/`HashSet` 中会出错。

```java
public class Account {
    private String name;
    private int balance;

    // getters & setters ...

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Account account = (Account) o;
        return balance == account.balance && Objects.equals(name, account.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, balance);
    }

    public static void main(String[] args) {
        Account a1 = new Account("zs", 100);
        Account a2 = new Account("zs", 100);
        System.out.println(a1.equals(a2)); // true

        Map<Account, String> retMap = new HashMap<>();
        retMap.put(a1, "hello");
        System.out.println(retMap.get(a2)); // 正确重写后输出 "hello"，否则 null

        Set<Account> retSet = new HashSet<>();
        retSet.add(a1);
        System.out.println(retSet.contains(a2)); // true，否则 false
    }
}
```

---

## 泛型

将类型参数化，声明类/接口/方法时使用类型形参，使用时再指定具体类型。  
**优点**：编译期类型安全检查、消除强制转换、提高代码复用性。

```java
public final class Optional<T> {                     // 泛型类
    private static final Optional<?> EMPTY = new Optional<>(); // ? 类型通配符
    public <U> Optional<U> map(Function<? super T, ? extends U> mapper) { ... } // 泛型方法，上下界限定
}
```

通配符说明：  
- `?`：任意类型  
- `? extends U`：上限通配（U 或其子类）  
- `? super T`：下限通配（T 或其父类）

---

## 反射

运行时动态获取类信息、创建对象、调用方法、操作属性。  
常用于框架设计（如 Spring、JDBC 驱动加载）。

```java
public static void main(String[] args) throws Exception {
    Class<?> aClass = Class.forName("java.util.ArrayList");
    Constructor<?> constructor = aClass.getConstructor(int.class);
    Object list = constructor.newInstance(3);
    Method addMethod = aClass.getMethod("add", Object.class);
    addMethod.setAccessible(true);   // 暴力访问
    addMethod.invoke(list, "hello");
    addMethod.invoke(list, "world");
    System.out.println(list);        // [hello, world]
}
```

---

## 注解

一种元数据，可标注类、方法、字段等，配合反射实现自定义功能。

```java
@Target(ElementType.TYPE)           // 作用目标
@Retention(RetentionPolicy.RUNTIME) // 生命周期
@Documented                         // 包含在 javadoc 中
@Inherited                          // 允许子类继承
public @interface Component {
    String value() default "";
}
```

---

## 异常

用于处理程序运行时的错误，增强健壮性和可维护性。

### 异常体系

```
Throwable
├── Error（JVM 错误，不强制处理）
└── Exception
    ├── RuntimeException（非受检异常，如 NullPointerException）
    └── 受检异常（Checked Exception，必须显式处理，如 IOException）
```

### 处理机制

1. **捕获**：`try-catch-finally`，`finally` 总会执行（除非 `System.exit()`）。  
2. **声明**：方法签名后使用 `throws` 声明可能抛出的受检异常。  
3. **抛出**：`throw new Exception()` 主动抛出异常，常用于业务逻辑。  
4. **try-with-resources**（Java 7+）：自动关闭实现了 `AutoCloseable` 的资源。

---

## 集合

### 集合框架概览

```
Collection（单列集合）
├── List：有序可重复
│    ├── ArrayList：数组实现，查询快，增删慢
│    ├── LinkedList：双向链表，增删快，查询慢
│    └── CopyOnWriteArrayList：写时复制，适合读多写少并发场景
├── Set：无序不可重复
│    ├── HashSet：基于 HashMap，散列存储
│    │    └── LinkedHashSet：维护插入顺序
│    └── TreeSet：红黑树，元素自然排序或定制排序
Map（双列集合）：Key 本质是 Set
├── HashMap：散列存储
└── ConcurrentHashMap：线程安全的 HashMap
```

### Iterator 迭代器

统一的遍历接口，将存储结构与遍历逻辑分离。支持在遍历时安全删除元素，并发安全。

```java
List<String> list = new ArrayList<>(Arrays.asList("A", "B", "C"));
Iterator<String> iterator = list.iterator();
while (iterator.hasNext()) {
    String s = iterator.next();
    if ("B".equals(s)) {
        iterator.remove();  // 安全删除
    }
}

// LinkedList 应使用迭代器而非索引遍历，避免 O(n²) 效率
LinkedList<String> linkedList = new LinkedList<>();
// ❌ 低效：for (int i=0; i<linkedList.size(); i++)  linkedList.get(i);
// ✅ 高效：使用迭代器
Iterator<String> iter = linkedList.iterator();
while (iter.hasNext()) {
    String s = iter.next();
}
```

**双向迭代器 ListIterator**  
可向前/向后遍历，并能在当前位置修改或添加元素。

```java
List<String> list = Arrays.asList("A", "B", "C");
ListIterator<String> listIter = list.listIterator();
// 向前遍历
while (listIter.hasNext()) { System.out.println(listIter.next()); }
// 向后遍历
while (listIter.hasPrevious()) { System.out.println(listIter.previous()); }
// 修改
listIter.set("New Value");
// 添加
listIter.add("Inserted");
```

### 集合排序

**Comparator 定制排序**

```java
TreeSet<Account> ts = new TreeSet<>(new Comparator<Account>() {
    @Override
    public int compare(Account o1, Account o2) {
        return o1.getBalance() - o2.getBalance();
    }
});
ts.add(new Account("zs", 100));
ts.add(new Account("ls", 200));
ts.add(new Account("ww", 50));
ts.forEach(a -> System.out.println(a.getName() + ":" + a.getBalance()));
```

**Comparable 自然排序**

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Person implements Comparable<Person> {
    private String name;
    private int age;

    @Override
    public int compareTo(Person o) {
        return this.age - o.age;
    }

    public static void main(String[] args) {
        List<Person> list = new ArrayList<>();
        list.add(new Person("ls", 30));
        list.add(new Person("ww", 10));
        list.add(new Person("zs", 20));

        // 使用 Stream + Comparator.comparing 进行排序
        List<Person> sorted = list.stream()
                .sorted(Comparator.comparing(Person::getAge).reversed())
                .collect(Collectors.toList());
        sorted.forEach(a -> System.out.println(a.getName() + ":" + a.getAge()));
    }
}
```

### Deque 双端队列

可用作栈（LIFO）或队列（FIFO）。

```java
// 栈
Deque<String> stack = new ArrayDeque<>();
stack.push("a"); stack.push("b"); stack.push("c");
while (!stack.isEmpty()) System.out.print(stack.pop() + " "); // c b a

// 队列
Deque<String> queue = new LinkedList<>();
queue.offer("A"); queue.offer("B"); queue.offer("C");
while (!queue.isEmpty()) System.out.print(queue.poll() + " "); // A B C
```

### Map 遍历

```java
Map<String, Integer> map = new ConcurrentHashMap<>();
// 方式一：entrySet（推荐，一次获取 key 和 value）
for (Map.Entry<String, Integer> entry : map.entrySet()) {
    System.out.println(entry.getKey() + ":" + entry.getValue());
}
// 方式二：Lambda
map.forEach((k, v) -> System.out.println(k + ":" + v));
```

---

## 流

以程序为主体：向程序输入为**输入流**，从程序输出为**输出流**。

### 序列化

实现 `Serializable` 接口，并定义 `serialVersionUID`。`transient` 修饰的属性不会被序列化。  
- **序列化**：将对象转换为字节序列，可持久化或传输。  
- **反序列化**：从字节序列恢复对象。

### 文件拷贝

```java
// 字节流方式（适合所有文件）
private static void copyFileByteStream(String src, String dist) throws IOException {
    try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(src));
         BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(dist))) {
        byte[] buffer = new byte[1024];
        int bytesRead;
        while ((bytesRead = in.read(buffer)) != -1) {
            out.write(buffer, 0, bytesRead);
        }
    }
}

// 字符流方式（适合文本文件）
private static void copyFileChar(String src, String dist) throws IOException {
    try (BufferedReader reader = new BufferedReader(new FileReader(src));
         BufferedWriter writer = new BufferedWriter(new FileWriter(dist))) {
        String line;
        while ((line = reader.readLine()) != null) {
            writer.write(line);
            writer.newLine();
        }
    }
}
```