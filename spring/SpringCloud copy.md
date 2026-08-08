---
title: SpringCloud
date: 2023-06-07 17:00:45
tags:
  - TechBase
categories: Frameworks
---

速通视频：
> https://www.bilibili.com/video/BV1UJc2ezEFU?spm_id_from=333.788.videopod.sections&vd_source=88f2d67f21120fbed5f365a6638870f5


代码参考：
[https://github.com/nacycher/study-cloud/blob/master/services/pom.xml](https://github.com/nacycher/study-cloud/blob/master/services/pom.xml)


视频的版本依赖参考：

jdk 17-->SpringBoot 3.3.4 --> SpringCloud 2023.0.3 --> SpringCloud alibaba 2023.0.3.2

Nacos 2.4.3 ---> Sentinel 1.8.8 --> Seata 2.2.0


### nacos


### openFeign
> RPC框架：rpc主要用于系统内部微服务的相互调用


### SpringCloud Gateway

> https://www.baeldung.com/spring-cloud-custom-gateway-filters

```yml
spring:
  cloud:
    gateway:
      routes:
        - id: product-route
          uri: lb://service-product
          predicates:
            - Path=/product/**
          filters:
            - Unix=mobile
            - RewritePath=/product/(?<segment>.*),/product/$\{segment}
```

### Seata

### Sentinel