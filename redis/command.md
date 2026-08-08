
```bash
# 安装并启动（Docker）
docker run -id --name myredis -p 6379:6379 redis:latest
docker exec -it myredis redis-cli

# 密码设置
config set requirepass yourpass
auth yourpass

# 基本操作
ping            # 检查连接
select 1        # 切换数据库（0~15）
keys *          # ⚠️ 生产慎用，会阻塞，推荐用 scan
flushdb         # 清空当前库
dbsize          # 查看 key 数量
```

### 3.2 String

```bash
set vip yes
get vip
type vip
expire vip 30
ttl vip          # -2 已失效，-1 永不过期

incr count
incrby count 20
decr count

getrange key 2 4       # 截取子串
setrange key 1 abc     # 从指定位置替换
mset k1 v1 k2 v2       # 批量设置
mget k1 k2             # 批量获取
```

### 3.3 List

```bash
lpush list a b c       # 左插入 -> c b a
rpush list 1 2 3       # 右插入 -> a b c 1 2 3
lpop list               # 左侧弹出
rpop list               # 右侧弹出
lrange list 0 -1        # 查看全部
llen list               # 列表长度
lindex list 0           # 按索引取值
```

### 3.4 Set

```bash
sadd set1 a b c d
srem set1 a             # 删除元素
smembers set1           # 获取所有成员
srandmember set1 2      # 随机获取 2 个（抽奖）
spop set1               # 随机移除一个
sdiff set1 set2         # 差集
sinter set1 set2        # 交集
sunion set1 set2        # 并集
sismember set1 a        # 判断是否存在
```

### 3.5 Hash

```bash
hset user name jack age 20
hget user name
hmget user name age
hgetall user            # ⚠️ 数据量大时会阻塞，改用 hscan
hexists user name
hdel user age
hlen user
```

### 3.6 ZSet

```bash
zadd score 100 math 95 english 80 chinese
zrange score 0 -1 withscores   # 按分数升序
zrevrange score 0 -1 withscores # 降序
zrank score english             # 升序排名（从0开始）
zscore score math               # 获取分数
zrangebyscore score 90 100      # 按分数范围查询
zincrby score 5 math             # 增加分数
```

### 3.7 Geo

```bash
geoadd city 118.89 31.32 nanjing
geopos city nanjing
geodist city nanjing beijing km     # 距离（km/m/mi/ft）
georadius city 120 30 500 km withcoord withdist count 5
georadiusbymember city nanjing 300 km
geohash city nanjing
zrange city 0 -1   # Geo 底层是 ZSet，可直接使用 ZSet 命令
```

### 3.8 HyperLogLog

```bash
pfadd uv user1 user2 user3
pfcount uv                       # 返回近似基数
pfmerge total uv1 uv2            # 合并多个 HyperLogLog
```

### 3.9 Bitmap

```bash
setbit sign:2025:uid 1001 1      # 用户1001打卡
getbit sign:2025:uid 1001
bitcount sign:2025:uid            # 总打卡人数
bitop and result sign1 sign2     # 位运算统计连续打卡等
```

### 3.10 实用运维命令

```bash
# 避免 keys *，使用 scan 游标迭代
scan 0 match user:* count 100

# 查看 key 占用内存
memory usage keyname

# 查找大 key
redis-cli --bigkeys

# 实时监控（每秒输出一次，共10次）
redis-cli --stat -i 1 -n 10

# 客户端连接数
info clients

# 命中率监控
info stats | grep keyspace
```

> Key 命名建议：`业务:模块:ID`，如 `login:token:abc123`，长度不超过 44 字节（embstr 优化），value 大小尽量 <10KB，集合元素 <1000。

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
