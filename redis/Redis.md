---
title: Redis
date: 2023-03-11 12:00:45
tags:
  - TechBase
categories: database
---


## 一、典型应用场景

| 场景             | 说明                                                                                         | 涉及数据结构             |
|------------------|----------------------------------------------------------------------------------------------|--------------------------|
| 缓存             | 加速数据读取，降低数据库压力；需重点处理穿透、击穿、雪崩等问题。                              | String、Hash             |
| 分布式 Session   | 统一管理登录态，解决集群 Session 共享问题。                                                  | String、Hash             |
| 计数器/限流      | 高并发下的点赞、库存扣减、接口频控等。                                                       | String（incr）、ZSet     |
| 排行榜           | 按分数排序的实时榜单（如积分排行、热度排序）。                                               | ZSet                     |
| 附近商户/地理位置| 计算两点间距离、查询半径内的门店等。                                                         | Geo                      |
| 消息队列         | 轻量级异步解耦，支持 List（阻塞队列）、Pub/Sub、Stream 三种模式。                            | List、Stream             |
| 用户签到/统计    | 日活月活、用户签到、去重统计等。                                                             | Bitmap、HyperLogLog      |
| 分布式锁         | 保证分布式环境下资源互斥访问。                                                               | String + Lua             |

推荐阅读：
- [Redis 核心专栏](https://juejin.cn/column/6963184822332325919)
- [Redis 常见问题总结](https://juejin.cn/post/6844903982066827277)

---

## 二、数据类型总览

| 数据类型   | 可以存储的值           | 常用操作                                                      | 典型场景                   |
|------------|------------------------|---------------------------------------------------------------|----------------------------|
| **String** | 字符串、数值           | get/set、incr/decr、过期设置                                   | 缓存、计数器、分布式锁     |
| **List**   | 有序可重复的字符串列表 | lpush/rpush、lpop/rpop、lrange                                 | 消息队列、最新列表         |
| **Set**    | 无序不重复的字符串集合 | sadd、srem、sinter、sunion、sdiff                               | 标签、好友关系、抽奖       |
| **Hash**   | 键值对集合（对象属性） | hset/hget、hmset/hmget、hgetall                                | 存储对象、购物车           |
| **ZSet**   | 带分数的有序集合       | zadd、zrangebyscore、zrank                                    | 排行榜、延迟任务           |
| **Geo**    | 地理位置信息           | geoadd、georadius、geodist                                    | 附近的人、门店定位         |
| **HyperLogLog** | 基数统计         | pfadd、pfcount、pfmerge                                        | UV 统计、去重估算          |
| **Bitmap** | 位图（0/1 标记）       | setbit、getbit、bitcount                                       | 签到打卡、用户画像标签     |

---

## 三、常用命令速查

https://github.com/zljin/cheatsheet/blob/master/redis/command.md

```bash
redis-cli -h 127.0.0.1 -p 6379 -a password
ping            # 检查连接
select 1        # 切换数据库（0~15）
set vip yes
get vip
keys *          # ⚠️ 生产慎用，会阻塞，推荐用 scan
flushdb         # 清空当前库
dbsize          # 查看 key 数量
```

> Key 命名建议：`业务:模块:ID`，如 `login:token:abc123`，长度不超过 44 字节（embstr 优化），value 大小尽量 <10KB，集合元素 <1000。

---

## 四、分布式缓存实战

### 4.1 缓存读写模式

**Cache Aside（旁路缓存）**：最常用的模式。
- **读**：先读缓存，命中则返回；未命中则查 DB，写入缓存后返回。
- **写**：先更新 DB，再删除缓存（或更新缓存，推荐删除）。

### 4.2 缓存不一致及解决方案

**原因**：并发读写、双写顺序错误、缓存更新失败等。

**解决方案**：
1. **延迟双删**：更新 DB 后删除缓存，短暂延时（如 500ms）后再删一次，避免并发旧数据写回。
2. **设置过期时间**：即使有不一致，过期后自动恢复。
3. **基于 binlog 的异步更新**：监听 MySQL binlog，通过 Canal 等组件异步刷新缓存。
4. **写后即删**：更新 DB 后直接删除缓存，等待下次查询重建，简单有效。

### 4.3 缓存穿透、击穿、雪崩

| 问题         | 描述                                                         | 解决方案                                                                                     |
|--------------|--------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| **缓存穿透** | 查询不存在的数据（DB 和缓存均无），请求直达 DB。              | ① 缓存空值（短过期时间）② 布隆过滤器提前拦截                                                |
| **缓存击穿** | 热点 key 过期瞬间，大量请求直冲 DB。                          | ① 热点数据永不过期（逻辑过期）② 互斥锁保证只有一个线程回源重建                                |
| **缓存雪崩** | 大量 key 同时过期或 Redis 宕机，导致 DB 瞬间高压。            | ① 过期时间加随机值 ② 多级缓存（本地+Redis）③ 限流降级 ④ 高可用（主从+哨兵/集群）            |

### 4.4 缓存预热

系统上线或重启后，提前将热点数据加载到缓存中，避免冷启动流量直接打到 DB。  
实现方式：
- 启动时通过后台任务批量写入缓存；
- 利用本地消息队列异步加载；
- 使用 Redis 的 `RDB/AOF` 备份快速恢复。

### 4.5 缓存降级

当 Redis 不可用或压力过大时，自动降级非核心功能（如推荐、榜单），只保证核心业务（如订单、库存），可以通过熔断组件（如 Hystrix/Sentinel）实现。

### 4.6 过期策略与内存淘汰

**Redis 过期键删除策略**：惰性删除 + 定期删除。
- **惰性删除**：访问 key 时检查是否过期，CPU 友好，但可能堆积过期 key。
- **定期删除**：每秒执行 10 次（默认），随机抽取部分 key 检查，删除过期键。

**内存淘汰策略**（`maxmemory-policy`）：
- `noeviction`：不淘汰，写操作报错。
- `allkeys-lru`：所有 key 中淘汰最近最少使用的（**推荐通用场景**）。
- `volatile-lru`：仅设置过期时间的 key 中淘汰 LRU。
- `allkeys-lfu` / `volatile-lfu`：淘汰使用频率最低的 key（适合热点/非热点分明场景）。
- `volatile-ttl`：淘汰剩余 TTL 最短的 key。

```bash
# 推荐配置
maxmemory 2gb
maxmemory-policy allkeys-lru
```

**避免雪崩**：设置过期时间时加上随机偏移，如 `expire key 300 + random(0,60)`。

---

## 五、分布式锁

### 5.1 单节点 Redis 锁的正确实现

```bash
# 获取锁：SET key value NX PX 30000  （NX: 不存在时才设置, PX: 毫秒）
SET lock:order:1001 unique_value NX PX 30000

# 释放锁（Lua 脚本保证原子性，仅删除自己的锁）
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
```

### 5.2 锁续期：Redisson 看门狗机制

当业务执行时间可能超过锁的过期时间时，需要自动续期。Redisson 的 **看门狗（Watchdog）** 机制解决了该问题。

**原理**：
- 若未显式指定 `leaseTime`（即 `-1`），看门狗会启动；
- 每隔 **10 秒**（锁过期时间 30 秒的 1/3）自动将锁的过期时间重置为 30 秒；
- 通过 **定时任务 + Lua 脚本** 实现续期的原子操作；
- 一旦客户端主动解锁或进程退出，看门狗停止续期，锁自动释放。

### 5.3 leaseTime 与看门狗的关系

```java
// 不指定leaseTime，看门狗自动续期，适合业务时间不确定
lock.tryLock(5, -1, TimeUnit.SECONDS);

// 指定leaseTime=10s，关闭看门狗，10秒后自动释放，适合短任务
lock.tryLock(3, 10, TimeUnit.SECONDS);
```

### 5.4 Redisson 实战示例

> 详细参考：[谷粒商城-分布式锁进阶](https://github.com/NiceSeason/gulimall-learning/blob/cb9daba842f5884312578a6e41db9f61ab7193af/docs/%E8%B0%B7%E7%B2%92%E5%95%86%E5%9F%8E%E2%80%94%E5%88%86%E5%B8%83%E5%BC%8F%E9%AB%98%E7%BA%A7.md#4-redisson)

```java
// 1. 可重入锁（ReentrantLock）
RLock lock = redisson.getLock("lock:order:" + orderId);
try {
    if (lock.tryLock(5, 30, TimeUnit.SECONDS)) {
        // 业务逻辑
    }
} finally {
    if (lock.isHeldByCurrentThread()) {
        lock.unlock();
    }
}

// 2. 公平锁
RLock fairLock = redisson.getFairLock("fair:lock");

// 3. 读写锁（RReadWriteLock）
RReadWriteLock rwLock = redisson.getReadWriteLock("rw:lock");
rwLock.readLock().lock();   // 读锁允许多个线程并发
rwLock.writeLock().lock();  // 写锁独占

// 4. 联锁（MultiLock）—— 多节点锁
RLock lock1 = redisson.getLock("lock1");
RLock lock2 = redisson.getLock("lock2");
RedissonMultiLock multiLock = new RedissonMultiLock(lock1, lock2);
multiLock.lock();

// 5. 红锁（RedLock）—— 更严格的分布式锁算法
```

**实战建议**：
- 锁粒度尽可能细，例如 `lock:order:1001` 而非 `lock:order`。
- 锁名称与业务强关联，避免无意义的全局锁。
- 设置合理的等待时间和过期时间，防止死锁。
- 务必在 `finally` 中释放锁，且判断 `isHeldByCurrentThread()`。
- 对核心业务建议使用 Redisson 封装好的 API，不要自己基于 `SETNX` 重复造轮子。

---

## 六、监控与运维

```bash
# 内存与命中率
redis-cli info memory
redis-cli info stats | grep keyspace

# 慢查询日志
CONFIG SET slowlog-log-slower-than 10000   # 超过 10ms 记录
slowlog get 10

# 查看连接数
info clients

# 实时吞吐量
redis-cli --stat -i 1

# 延迟诊断
redis-cli --latency
```

**告警指标**：
- 内存使用率 > 80%
- 连接数接近上限
- 慢查询数量持续增长
- 命中率 < 95%
- 主从复制延迟 > 10s

---

> Redis 是支撑高并发系统的利器，正确使用需要结合场景选择合适的数据结构、设计合理的 Key/Value 大小、做好缓存异常防护，并善用分布式锁保证数据一致性。生产环境务必配置好监控和告警，才能做到可观察、可运维。