---
title: SpringCloud
date: 2023-06-07 17:00:45
tags:
  - TechBase
categories: Frameworks
---

> 以 Spring Boot 为基石的微服务全家桶。**记住一句话：微服务就是"服务拆小 + 治理分散的坑"**，Spring Cloud 各组件各管一个坑。

速通视频：https://www.bilibili.com/video/BV1UJc2ezEFU
代码参考：https://github.com/nacycher/study-cloud

**版本对应（jdk17 时代）：**
```
SpringBoot 3.3.x → SpringCloud 2023.0.x → SpringCloud Alibaba 2023.0.x
Nacos 2.4.x / Sentinel 1.8.x / Seata 2.2.x
```

---

## 1. Nacos：注册中心 + 配置中心（微服务的地基）

- **注册中心**：服务启动时把自己注册进来，别人通过服务名找到你，替代手写 IP
- **配置中心**：把配置从代码里抽出来放 Nacos，改配置**不用重启**（配合 @RefreshScope）

```yml
# application.yml
spring:
  application:
    name: user-service
  cloud:
    nacos:
      discovery:
        server-addr: 127.0.0.1:8848   # 注册中心
      config:
        server-addr: 127.0.0.1:8848
        file-extension: yml           # DataID = user-service.yml
```

```java
@RefreshScope                 // 配合 Nacos 配置中心，改配置不重启
@Service
public class UserService { ... }
```

> 服务名为什么能当"域名"用：Nacos 注册后，Feign/Gateway 用服务名调用，Nacos 自动返回真实 IP 列表并做负载均衡。

---

## 2. OpenFeign：声明式远程调用（服务间通信）

> RPC 框架，服务 A 调服务 B 就像调自己接口一样。接口 + 注解，不用写 HTTP 代码。

```java
@FeignClient(name = "order-service")     // 调那个服务（Nacos里注册的名字）
public interface OrderClient {
    @GetMapping("/api/orders/{id}")       // 直接贴对方 Controller 的路径
    Order getOrder(@PathVariable Long id);
}

@Service
public class UserServiceImpl {
    @Autowired
    private OrderClient orderClient;      // 直接当本地 Bean 用
    public Order getOrder(Long id) { return orderClient.getOrder(id); }
}
```

**注意**：
- 调用方要加 `@EnableFeignClients` 或用 `@FeignClient` 手动注入
- 被调服务的超时：用 `application.yml` 里 `feign.client.config.default.connectTimeout/readTimeout`
- 和 gateway 的路径对不上时，用 `@FeignClient(path)` 补前缀

---

## 3. Spring Cloud Gateway：统一入口 + 路由转发（所有请求先过它）

```yml
spring:
  cloud:
    gateway:
      routes:
        - id: product-route
          uri: lb://service-product      # lb:// + 服务名，走注册中心负载均衡
          predicates:
            - Path=/product/**          # 匹配路径
          filters:
            - RewritePath=/product/(?<segment>.*),/product/$\{segment}   # 去掉前缀转发
```

**常用谓词 Predicate**：`Path=xx`、`Host=xx.com`、`Method=GET` → 决定"这个请求要不要走这条路由"。

---

## 4. Sentinel：限流 + 熔断 + 降级（保护服务不死）

> 应对突增流量：超过了限制直接拒绝/降级，别把服务打垮。

```java
@SentinelResource(value = "getOrder", fallback = "getOrderFallback")
public Order getOrder(Long id) {
    // 业务逻辑...
}

public Order getOrderFallback(Long id, Throwable e) {
    return new Order();   // 挂了返回兜底数据
}
```

- 规则（限流阈值、熔断条件）配置在 Sentinel 控制台，可**动态下发**，不用改代码
- 接入后 /api 分组资源，看 dashboard 里实时流量和慢调用

---

## 5. Seata：分布式事务（跨服务保持一致性）

> 前提是：`@Transactional` 只管本服务自己的事务，跨服务（A 下单 + B 扣库存）要 Seata 管。

- 只需在**全局入口方法**加 `@GlobalTransactional`，里面调用的服务方法仍用各自 `@Transactional`
- 默认 AT 模式：业务代码零侵入，Seata 代理帮你做 undo 日志回滚

```java
@GlobalTransactional(rollbackFor = Exception.class)   // 分布式事务入口
public void createOrder(...) {
    orderService.insert(order);     // 本服务事务
    stockClient.deductStock(...);   // 跨服务调用（Seata 统一回滚）
}
```

---

# reference

Spring Cloud 官方：https://spring.io/projects/spring-cloud