---
title: Spring
date: 2022-06-05 17:00:45
tags:
  - TechBase
categories: Frameworks
---

> Spring的核心：以bean为中心提供IOC和AOP的功能,简化开发JavaApp的框架
> SpringMVC：是webmvc框架，servlet的增强，提供丰富的Web开发功能
> SpringBoot：简化Spring繁杂配置，快速开发后台应用的框架
> SpringCloud: 以SpringBoot为基石，快速构建微服务架构，如解决微服务架构中的服务发现、配置管理、容错、路由等


## IOC解决那些问题

IOC为控制反转，将bean的生命周期统一交给Spring工厂管理，而不是直接new对象，通过依赖注入实现对象间的相互依赖
IOC容器有两种，BeanFactory:提供基础的依赖注入的能力,ApplicationContext:提供更强的事件发布,国际化支持等功能

注意：BeanFactory和FactoryBean区别
BeanFactory是Spring的一个IOC容器，用来对Bean进行实例化的
FactoryBean用来处理需要复杂初始化逻辑的Bean,如ProxyFactoryBean：用于创建 AOP 代理

### 依赖注入

依赖注入可通过字段注入，构造器注入(可保证依赖不为空，保证不可变性)，setter注入(支持循环依赖和写单例测试)
优点是松耦合,不关心依赖对象是如何创建的，具体如何实现的，由spring配置决定

注意的点：

> autowired和resource区别

|注解    | 包 | 匹配类型  | 使用场景                      |
|-------|------|---------|-----------------------------|
| autowired| Spring自带 | 类型匹配 | 可以用在构造器和setter注入 |
| resource | JDK自带    | 名称匹配,默认名称为字段名或方法名 | 不能用在构造器和setter注入 |

>Autowired可以用在Map上

```java
/**
 * 当@Autowired 用在 Map 上时，Spring 会自动将匹配特定类型的所有 Bean 注入到这 Map 中，
 * 其中 Map 的 key 默认是 Bean 的名称 (驼峰类命名，或者你自己指定一个名字也行)，value 是 Bean 的实例
 */
@Service
public class PaymentService {
    @Resource
    Map<String, PaymentProcessor> processorMap;
}
```


## AOP解决那些问题

定义：面向切面编程,动态封装一些可重用性的非业务代码(切面:封装用于横向插入方法的功能类),并通过动态代理的方式,生成对目标类进行加强的代理对象.
优点：复用功能性代码,消除样板代码
实现方式：JDK动态代理(实现接口的类增强)  cglib(实现类本身增强)

例子：通过AspectJ的表达式确定被增强目标和方法，通过@Around环绕通知，将新增的动态封装的代码织入到目标类生成增强的代理对象，曾经实现了一个审计日志切面,
@Tranactional也是基于事务实现的等等

### 使用AOP注意的点
1、同一个类方法调用不触发aop，因为没走代理
2、代理模式限制，final修饰的方法不能被增强,方法要为public

### 相关概念
Target(目标)：被增强的对象
Advice(通知)：切面具体的任务，即拦截后要做的事情
Joinpoint(连接点)：指的是可以拦截的点(方法)
Pointcut(切入点)：指的是真正被拦截到的点
Weaving(织入)：将Advice的应用到Target的过程
Proxy(代理)：被Advice增强后动态生成的代理对象


## Spring事务

### 事务失效的排查方法

1、@EnableTransactionManagement注解是否开启
2、数据库引擎是否支持事务，如MyISAM
3、@Tranactional注解是否遵循AOP的使用原则 --> 如内部方法调用,AOP就会失效,要拆出来一个service
4、异常是否被吞了，没有抛出或异常类型不匹配，默认只对RuntimeException回滚，最好指定
```java
@Transactional(propagation = Propagation.REQUIRED, rollbackFor = Exception.class)
```

### 如何开启Spring事务
1、打开开关@EnableTransactionManagement
2、声明式事务注解，指定事务传播和异常
3、编程式事务，手动开启事务commit事务

```java
//编程式事务例子
@Service
public class UserService {
    
    @Autowired
    private PlatformTransactionManager transactionManager;  // Spring自带
    
    @Autowired
    private UserMapper userMapper;  // MyBatis接口
    
    public void updateUser(User user) {
        // 1. 定义事务（事务传播级别设为REQUIRED）
        TransactionDefinition definition = new DefaultTransactionDefinition();
        
        // 2. 开启事务
        TransactionStatus status = transactionManager.getTransaction(definition);
        
        try {
            // 3. 业务操作（这3个操作要么都成功，要么都失败）
            userMapper.updateUser(user);        // 更新用户
            userMapper.addUserLog(user.getId()); // 添加日志
            userMapper.updateUserScore(user.getId(), 10); // 更新积分
            
            // 4. 提交事务（所有操作成功）
            transactionManager.commit(status);
            
        } catch (Exception e) {
            // 5. 回滚事务（任何异常就回滚）
            transactionManager.rollback(status);
            throw e;
        }
    }
}
```

### Spring事务传播

REQUIRED：当前存在事务则加入事务，没有则新创建，默认值，适合大多数场景
REQUIRES_NEW：始终创建新的事务，适合审计日志
SUPPORTS：当前存在事务则加入，否则不执行事务，适合查询场景
MANDATORY：必须有事务，否则报错，增强安全性检查
NOT_SUPPORTED: 当前有事务->事务挂起
NEVER: 当前有事务 ->抛出异常
NESTED: 当前有事务(主事务提交或者回滚会影响子事务) -> 开启嵌套子事务(独立提交或者回滚,不影响父)


## Bean的生命周期

![img](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/spring_bean_lifecycle.png)

```
ApplicationContext构造方法中有refresh()方法,是spring启动方法

1. BeanDefinitionReader读取bean.xml的类定义信息 --> ConcurrentHashMap<beanName,BeanDefinition>

2. BeanFactory读取BeanDefinition信息,进行实例化 ---> newInstance实例化此bean,未初始化,只是开辟一个空间

3. initializeBean()初始化Bean

3.1 ---> 通过populateBean()方法填充bean属性(如Autowired,Setter等)

3.2 ---> 调用BeanPostprocessor的前置后置方法,相当于一种插件,可以自定义bean的一些操作

3.3 ---> 执行初始化方法 @PostConstuct,InitializingBean.afterPropertiesSet,init-method

4. bean in use

5. bean destory
```

### Bean的作用域

单例：独一无二，默认的配置，无状态，节省内存空间，Spring自动管理生命周期，自动销毁
如UserDao,UserService这种一般都是单例

原型：每次获取Bean是都会创建新的实例，Spring不管理销毁，适合有状态的
如用户表单提交，需要独立的对象与存有状态的信息，一般这种用web作用于

Web作用域：
request: 一次http请求创建一个bean，请求结束销毁
session: 每个会话创建一个bean，会话结束销毁

实际选择时考虑以下几点：
组件是否有状态，并发访问情况，内存占用和创建的成本
有状态，多线程就用原型模式


### 如何解决循环依赖

springboot 2.6版本以上后，默认关闭循环依赖，如需则配置打开开关

构造器注入不支持循环依赖，用setter注入可支持

采用三级缓存实现

第一层map: 存放初始化好的单例对象
第二层map: 存放实例化对象
第三层map: 存放Bean的工厂对象，AOP代理

为什么一定要三级缓存，为了解决Bean需要被AOP代理，最终注入的是代理对象而不是原始对象，
三级缓存中的工厂在合适的时机创建代理对象，而不是提前曝光原始对象

A->B:
创建A的实例-->将A的创建工厂放入三级缓存
填充A的属性-->发现依赖B--->转而创建B
创建B的实例-->将B的创建工厂放入三级缓存
填充B的属性-->发现依赖A--->尝试从缓存中获取A
从三级缓存中获取A-->然后将A的引用存入二级缓存--->删除三级缓存的A工厂
 B注入早期的A引用--->B初始化完成-->B放入一级缓存，并删除三级缓存中B的创建工厂
继续填充A的属性-->在一级缓存中拿到B的初始化对象-->A初始化完成，放入一级缓存

## 用到的设计模式

工厂模式 BeanFactory,ApplicationContext
单例模式  bean的默认作用于singleton
代理模式 AOP的jdk代理等
观察者模式 ApplicationContext.pushEvent ,ApplicationEvent 和 ApplicationListener
模版方法 RestTemplate

## Spring常用的核心注解

https://github.com/Snailclimb/JavaGuide/blob/main/docs/system-design/framework/spring/spring-common-annotations.md