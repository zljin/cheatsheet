---
title: SpringBoot
date: 2022-06-06 17:00:45
tags:
  - TechBase
categories: Frameworks
---

springboot的完整项目实战

https://github.com/zljin/ms-app?tab=readme-ov-file#how2springboot

https://github.com/zljin/flashbuy


## Springboot

1、简化配置，引入”约定大于配置“理念，采用注解和自动配置，快速启动一个应用
2、简化依赖管理，引入“starter”的概念，一个starter自动引入一组相关版本兼容的依赖
3、简化部署，淘汰传统的war包部署，采用内嵌web容器的可执行的jar包，java -jar就可执行
4、是[[SpringCloud]]的基石

### SpringBoot自动装配原理

自动装配：是约定大于配置体现，根据引入的jar包依赖，自动配置Spring所需的Bean，简化手动配置

核心原理：

```
启动流程：
@SpringBootApplication
    ↓
@EnableAutoConfiguration
    ↓
AutoConfigurationImportSelector.selectImports()
    ↓
SpringFactoriesLoader.loadFactoryNames() 
    ↓ 扫描所有jar包的
读取 META-INF/spring.factories
    ↓ 获取所有
自动配置类全限定名列表
    ↓ 经过
条件注解过滤 (@ConditionalOnClass, @ConditionalOnBean等)
    ↓ 最终
有效的自动配置类
    ↓ 执行
@Configuration类 → 创建Bean → 注入Spring容器
```


### 如何内嵌web容器的

第一步：@SpringBootApplication-->@EnableAutoConfiguration触发自动配置，扫描所有 spring.factories 中的配置类
AutoConfigurationImportSelector.getCandidateConfigurations

第二步：刷新应用上下文时 即调用onRefresh()方法，检测到 Web 依赖（@ConditionalOnWebApplication）
就创建内嵌服务器（Tomcat）

第三步：服务器在 refreshContext() 过程中自动启动，监听 8080 端口

![img](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/springboot_start_step.png)

### 如何开发一个starter

> Spring Boot Starter 是一个依赖描述符，通过约定优于配置的原则，实现自动配置，简化第三方库的集成

```
my-spring-boot-starter
├── src/main/java
│   └── com/example/autoconfigure
│       ├── MyServiceAutoConfiguration.java  # 自动配置类
│       ├── MyServiceProperties.java         # 配置属性类
│       └── MyService.java                   # 核心服务类
└── src/main/resources
    └── META-INF
        └── spring.factories                 # 自动配置注册文件
```

1.引入autoconfigure和starter的基础依赖
2.定义配置属性类，@ConfigurationProperties
3.定义自动配置类，@EnableConfigurationProperties,@ConditionalOnProperty,@ConditionalOnClass
4.自动配置注册文件spring.factories

```
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.autoconfigure.MyServiceAutoConfiguration
```

### 启动时实现缓存预热

1、使用@PostConstruct注解，在缓存服务Bean初始化完成后立即执行预热
2、使用实现CommandLineRunner接口，且@Order(1)可以指定顺序，在Spring上下文刷新启动完成前执行

这两个都算同步预热，适合核心商品和促销数据
优点：实现简单
缺点：数据过大，影响启动时间，若出现异常，影响启动

3、ApplicationReadyEvent+异步方法预热，
ApplicationReadyEvent是等所有 Bean 都初始化完成后再执行预热，不会影响应用启动，然后用线程池异步执行一些方法
