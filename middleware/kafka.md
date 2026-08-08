---
title: Kafka
date: 2022-11-13 12:00:45
tags:
  - TechBase
categories: Middleware
---


> 消息队列主要用作解耦，削峰，异步的功能，kafka的特点是更高的并发量，毫秒级延迟，易扩展

[[Docker]] 文档中有安装步骤

## 架构组成

![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/kafka1.png?raw=true)

zookeeper: 存放kafka的metadata

Producer：消息生产者，就是向 Kafka broker 发消息的客户端

Consumer：消息消费者，向 Kafka broker 取消息的客户端

broker：一个kafka服务器,接受生产者发送消息并存入磁盘,服务消费者拉取分区消息的请求,返回目前已经提交的消息

cluster：若干个broker组成cluster,其中某个broker作为leader管理集群

Topic：逻辑上了的消息队列名称

Partition：Topic的物理存储的队列，一个topic的物理存储是由多个Partition组成(扩展性,支持水平扩展)

每个Partition中的消息都是有序的，生产的消息被不断追加到Partition上,其中的每一个消息都被赋予了一个唯一的offset值

Offset：offset 是消息在分区中的唯一标识，Kafka 通过它来保证消息在分区内的顺序性，不过 offset 并不跨越分区，也就是说，Kafka 保证的是分区有序性而不是主题有序性

Replication：同一 partition可能会有多个replication，需要在这些 replication 之间选出一个leader，producer 和 consumer 只与这个 leader 交互，其它 replication 作为 follower 从 leader 中复制数据

## 常见问题

### 如何保证不丢消息

生产者丢消息

1.  添加异步回调函数，知道发送成功还是失败
2.  网络不可达，添加重试次数 spring.kafka.producer.retries:3

> <https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_kafka/src/main/java/com/zljin/config/KafkaSendUtil.java#L87>

队列丢消息

1.  partition添加多个replication>=3
2.  设置接收策略,至少写入两个副本才算发送成功

> <https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_kafka/src/main/resources/application.yml#L9>

    spring.kafka.producer.acks:all  # 所有副本都接收消息才算发送成功
    spring.kafka.producer.acks:1  # 只有leader接收就算发送成功
    spring.kafka.producer.acks:0  # 不管,发送就代表成功

    replication.factor >= 3(分区一主多从，保证高可用)
    min.insync.replicas > 1（消息至少要被写入到 2 个副本才算是被成功发送）

消费者丢消息

1.  设置手动提交，关闭自动提交，当消息真正消费后，返回给kafka一个确认标识

> <https://github.com/zljin/Spring-Boot-In-Action/blob/master/springboot_kafka/src/main/java/com/zljin/config/KafkaConsumerListener.java#L33>

### 消费的顺序性

1、单个分区内的消息是严格有序的
一个topic对应一个partition对应一个consumer,且consumer单线程消费

2、对于不同分区
在生产端：
给消息指定一个key,相同key的相关消息进入一个partition,同一个partition一定是有序的
比如订单系统使用订单 ID 作为 Key，确保同一订单的所有操作（创建、支付、发货）都进入同一分区

在消费端：
消费者拿到消息先不直接消费，而是根据key进行哈希操作，将key相同的数据发送到相同的内存队列中
消费者线程直接从内存队列消费即可保证顺序性

### 重复消费

> 保持幂等性

如何保持幂等性？
1.在内存中维护一个Set集合
2.数据库设置唯一键
3.先拿唯一键进行查询,查询成功丢弃，不存在则写入

### 消息积压

1.  实时消费任务宕机导致的消息积压
    创建新的topic并配置更多数量的分区，将积压消息的topic消费者逻辑改为直接把消息打入新的topic，将消费逻辑写在新的topic的消费者中

2.  kafka分区设置不合理和消费者消费能力不足优化

数据量大，可添加topic的partition(提高consumer的吞吐量)，同时提升消费组的消费者数量

1.  kafka消息key设置优化

使用Kafka Producer消息时，可以为消息指定key，但是要求key要均匀，否则会出现Kafka分区间数据不均衡。
所以根据业务，合理修改Producer处的key设置规则，解决数据倾斜问题。

## Springboot集成

<https://github.com/zljin/Spring-Boot-In-Action/tree/master/springboot_kafka>

## 常用命令行

```shell
docker exec -it kafka /bin/bash

# topic相关
kafka-topics.sh --help


## 创建topic
kafka-topics.sh --create --topic topicA \
--zookeeper zookeeper:2181 --replication-factor 1 \
--partitions 1


## 查看topic基本信息
kafka-topics.sh --zookeeper zookeeper:2181 \
--describe --topic topicA

## 查看其他topic信息
kafka-topics.sh --zookeeper zookeeper:2181 --list

# 生产消息 
kafka-console-producer.sh --topic=topicA \
--broker-list kafka:9092

# 消费消息
kafka-console-consumer.sh \
--bootstrap-server kafka:9092 \
--from-beginning --topic topicA

/data/kafka_2.11-1.1.0/bin/kafka-console-consumer.sh --bootstrap-server 
platform-kafka.rootcloud.name:9092 --property print.key=true --topic new_device_from_global

-- 6. 查看消费进度
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --describe --group group1

```

