---
title: RabbitMQ
date: 2022-10-13 12:00:45
tags:
  - TechBase
categories: Middleware
---


## 安装

```sh
docker run -id -p 5672:5672 -p 15672:15672 --name dev-rabbitmq rabbitmq:management

http://localhost:15672/#/   # guest guest
```

## 基本概念

publisher：生产者

exchange个：交换机,负责消息路由. 有三种类型分别代表三种消息模型: direct,fanout,topic

queue：队列，存储消息

virtualHost：虚拟主机，隔离不同租户的exchange、queue、消息的隔离

consumer：消费者

```
publisher ---> {(exchange ---> queue) virtualHost} ---> consumer
publisher ---> {(exchange ---> queue) virtualHost} ---> consumer
publisher ---> {(exchange ---> queue) virtualHost} ---> consumer
```

## springboot集成

> https://github.com/zljin/Spring-Boot-In-Action/tree/master/springboot_rabbitmq

```xml
<!-- AMQP 依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-xml</artifactId>
    <version>2.9.10</version>
</dependency>
```

```yml
spring:
  rabbitmq:
    host: localhost
    port: 5672
    username: guest
    password: guest
    publisher-returns: true # 消息正确抵达队列进行回调
    template:
      mandatory: true  # 强制要求消息必须被路由到一个队列。如果消息无法路由，会触发一个回调，通常用于处理无法投递的消息
    listener:
      simple:
        acknowledge-mode: manual # 手动签收
```

## Exchange的三种消息模型

direct
点对点模式，消息中的路由键如果和 Binding 中的 bindingkey 一致，交换器就将消息发到对应的队列中。

fanout
广播模式，每个发到 fanout 类型交换器的消息都会分到所有绑定的队列上去

topic (企业常用,重点关注此即可)

主题模式，Topic Exchange 可通过通配符路由键匹配映射多个Queue

## 消息可靠性发送与接收消费

发送： https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_rabbitmq/src/main/java/com/zljin/config/MyRabbitConfig.java#L55

```java
@Slf4j
@Configuration
public class MyRabbitConfig {

    RabbitTemplate rabbitTemplate;

    /**
     * 定制RabbitTemplate
     * @param connectionFactory
     * @return
     */
    @Primary
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory){
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        this.rabbitTemplate = rabbitTemplate;
        rabbitTemplate.setMessageConverter(jsonMessageConverter());
        initRabbitTemplate();
        return rabbitTemplate;
    }

    /**
     * 使用JSON序列化机制，进行消息转换
     */
    @Bean
    public MessageConverter jsonMessageConverter(){
        return new Jackson2JsonMessageConverter();
    }

    public void initRabbitTemplate(){
        rabbitTemplate.setConfirmCallback(new RabbitTemplate.ConfirmCallback() {
            @Override
            public void confirm(CorrelationData correlationData, boolean ack, String cause) {
                log.info("confirm...correlationData[{}]==>ack[{}]==>cause[{}]",correlationData,ack,cause);
            }
        });

        rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            @Override
            public void returnedMessage(Message message, int replyCode, String replyText, String exchange, String routingKey) {
                log.info("Fail Message[{}]==>replyCode[{}]==>replyText[{}]===>exchange[{}]===>routingKey[{}]",message,replyCode,replyText,exchange,routingKey);
            }
        });
    }
}
```

接收： https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_rabbitmq/src/main/java/com/zljin/listener/OrderCloseListener.java#L27

```java
/**
 * 30分钟后检查订单状态是否已经完成
 *
 * 若完成不处理，否则释放库存，关闭订单
 */
@RabbitListener(queues = "order.release.order.queue")
@Service
public class OrderCloseListener {

    @RabbitHandler
    public void listener(Map entity, Channel channel, Message message) throws IOException {
        try{
            System.out.println("订单处理"+entity);
            //手动签收 ok
            channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);
        }catch (Exception e){
            //手动签收 reject
            channel.basicReject(message.getMessageProperties().getDeliveryTag(),true);
        }
    }
}
```

## 死信队列用法

> 死信队列即延迟队列，给消息设置ttl,然后去往delayqueue,常用于如订单竣工场景，需要等待客户30秒后支付，是一个异步且需要等待的业务场景常用此技术实现

https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_rabbitmq/src/main/java/com/zljin/config/MyOrderConfig.java#L21

```java
/**
 * 创建订单时消息会被发送至队列`order.delay.queue`，经过`TTL`的时间后消息会变成死信以`order.release.order`的路由键经交换机转发至队列`order.release.order.queue`，
 * 再通过监听该队列的消息来实现过期订单的处理
 */
@Configuration
public class MyOrderConfig {

    @Bean
    public Queue orderDelayQueue() {
        Map<String, Object> arguments = new HashMap<>();
        //出现dead letter之后将dead letter重新发送到指定exchange
        arguments.put("x-dead-letter-exchange", "order-event-exchange");
        //出现dead letter之后将dead letter重新按照指定的routing-key发送
        arguments.put("x-dead-letter-routing-key", "order.release.order");
        //控制消息的生存时间 60s
        arguments.put("x-message-ttl", 60000);
        return new Queue("order.delay.queue", true, false, false, arguments);
    }

    @Bean
    public Exchange orderEventExchange() {
        return new TopicExchange("order-event-exchange", true, false);
    }

    //创建订单后的路由到orderDelayQueue队列
    @Bean
    public Binding orderCreateOrderBingding() {
        return new Binding("order.delay.queue",
                Binding.DestinationType.QUEUE,
                "order-event-exchange",
                "order.create.order",
                null);
    }

    //过期消息的指定队列
    @Bean
    public Queue orderReleaseOrderQueue() {
        return new Queue("order.release.order.queue", true, false, false);
    }

    @Bean
    public Binding orderReleaseOrderBingding() {
        return new Binding("order.release.order.queue",
                Binding.DestinationType.QUEUE,
                "order-event-exchange",
                "order.release.order",
                null);
    }
}
```