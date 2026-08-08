---
title: MySQL
date: 2020-02-15 19:00:45
tags:
  - TechBase
categories: database
---

## 一、表设计原则

### 1. 范式化（3NF）

**目的**：减少数据冗余，避免更新异常，保证数据一致性。

- **第一范式（1NF）**：字段原子性，不可再分。
- **第二范式（2NF）**：满足 1NF，且非主键字段完全依赖主键（消除部分依赖）。
- **第三范式（3NF）**：满足 2NF，且非主键字段不传递依赖主键（消除传递依赖）。

**适用场景**：
- 核心业务表（如订单、用户、商品）应严格遵循 3NF，确保数据可靠。
- 例如：供应商信息只存一次，库存变动记录独立，避免更新时数据不一致。

### 2. 反范式化（适度冗余）

**目的**：为了查询性能，牺牲部分存储空间，减少关联查询。

**适用场景**：
- 高频报表查询，需要关联多张表，性能瓶颈明显。
- 可以创建**视图**（逻辑冗余）或增加冗余字段（物理冗余）。

**权衡**：更新冗余字段时要额外维护，需根据业务权衡。

---

## 二、索引优化

### 1. 索引失效场景（避免）

- `LIKE` 查询不以 `%` 开头（如 `'AB%'` 可用索引，`'%AB'` 不行）。
- `JOIN` 两表的字段类型不一致（隐式转换导致索引失效）。
- **最左前缀原则**：复合索引 `(a,b,c)`，查询条件必须包含 `a` 才能用索引；只用 `b,c` 或 `b` 无法命中。
- **隐式类型转换**：字符串字段用数字查询（如 `WHERE phone = 123`），会转换类型导致索引失效。
- 对索引列做运算或函数操作（如 `WHERE YEAR(date) = 2020`）。

### 2. 执行计划分析（EXPLAIN）

使用 `EXPLAIN SELECT ...` 查看执行计划，重点关注：

| 字段    | 说明                                                         |
| ------- | ------------------------------------------------------------ |
| `type`  | 访问类型，`ALL` 表示全表扫描，应避免；`ref`/`range` 为较好；`const`/`eq_ref` 最优。 |
| `key`   | 实际使用的索引，`NULL` 表示未使用索引。                      |
| `rows`  | 预估扫描行数，越大性能越差。                                 |
| `Extra` | `Using index`（覆盖索引，不需回表）优秀；`Using filesort` / `Using temporary` 需优化。 |

### 3. 索引类型详解

| 索引类型     | 特点                                                         |
| ------------ | ------------------------------------------------------------ |
| **主键索引（聚簇索引）** | 叶子节点直接包含完整行数据，数据按主键物理排序。主键查询只需一次 I/O。不允许 `NULL`，每个表只能有一个。 |
| **唯一索引** | 二级索引，叶子节点存储主键值，查询需要回表（通过主键再查一次）。允许有多个 `NULL` 值（InnoDB 中 `NULL` 可重复）。 |
| **普通索引** | 无唯一性约束，辅助索引。                                     |
| **全文索引** | 用于全文检索（`MATCH AGAINST`），MyISAM 和 InnoDB（5.6+）支持。 |
| **组合索引** | 多个字段联合索引，遵循最左前缀原则，可减少回表（覆盖索引）。 |

> 💡 **覆盖索引**：若查询字段全部在索引中，则无需回表，性能最佳。

---

## 三、事务

MySQL **InnoDB** 支持事务，MyISAM 不支持。

### 1. ACID 特性

- **原子性（Atomicity）**：事务不可分割，要么全部成功，要么全部失败。
- **一致性（Consistency）**：事务前后数据状态保持一致（如转账总额不变）。
- **隔离性（Isolation）**：并发事务之间互不干扰，由隔离级别控制。
- **持久性（Durability）**：提交后数据永久保存（即使宕机）。

### 2. 并发问题

| 问题         | 说明                                                   |
| ------------ | ------------------------------------------------------ |
| **脏读**     | 读取到另一个事务未提交的数据（可能被回滚）。           |
| **不可重复读** | 同一事务内两次读取同一行数据，结果不同（因其他事务更新并提交）。 |
| **幻读**     | 同一事务内两次范围查询，结果集行数变化（因其他事务插入/删除）。 |

### 3. 隔离级别（由低到高）

| 隔离级别       | 脏读 | 不可重复读 | 幻读 | 适用场景                     |
| -------------- | ---- | ---------- | ---- | ---------------------------- |
| **READ UNCOMMITTED** | ✅    | ✅          | ✅    | 几乎不用                     |
| **READ COMMITTED**   | ❌    | ✅          | ✅    | 多数业务可接受，如报表查询   |
| **REPEATABLE READ**  | ❌    | ❌          | ✅（InnoDB通过MVCC+间隙锁解决部分） | 电商、金融等默认选择（MySQL默认） |
| **SERIALIZABLE**     | ❌    | ❌          | ❌    | 强一致性，但性能极低，适合极严格场景 |

### 4. MVCC（多版本并发控制）

- **核心思想**：每行数据保存多个历史版本（通过隐藏字段 `DB_TRX_ID` 和 `DB_ROLL_PTR`）。
- **作用**：在 `READ COMMITTED` 和 `REPEATABLE READ` 级别下，事务启动时生成**一致性快照**（read view），读取快照中已提交的数据版本，从而避免脏读和不可重复读。
- **实现机制**：
  - `REPEATABLE READ`：事务开始时生成快照，整个事务期间使用同一快照，因此可重复读。
  - `READ COMMITTED`：每次查询重新生成快照，因此能看到其他事务已提交的最新数据。
- **优势**：读操作不加锁，提高并发性能。

---

## 四、锁机制

### 1. 悲观锁与乐观锁

| 锁类型       | 实现方式                             | 适用场景                 |
| ------------ | ------------------------------------ | ------------------------ |
| **悲观锁**   | `SELECT ... FOR UPDATE`（行锁/表锁） | 写多读少，冲突概率高     |
| **乐观锁**   | 版本号（version）或时间戳 CAS 重试   | 读多写少，冲突概率低     |

- **悲观锁示例**：
  ```sql
  -- 事务1
  START TRANSACTION;
  SELECT stock FROM goods WHERE id = 1 FOR UPDATE;
  -- 更新操作
  UPDATE goods SET stock = stock - 1 WHERE id = 1;
  COMMIT;
  ```

- **乐观锁示例**：
  ```sql
  -- 先查询版本号
  SELECT version, stock FROM goods WHERE id = 1;
  -- 更新时检查版本
  UPDATE goods SET stock = stock - 1, version = version + 1 
  WHERE id = 1 AND version = 旧版本号;
  ```

### 2. 死锁排查与解决

**死锁**：两个或多个事务相互持有对方需要的锁，导致永久等待。

- **排查方法**：
  - 执行 `SHOW ENGINE INNODB STATUS` 查看最近死锁信息。
  - 使用 `performance_schema` 中的 `events_transactions_current` 等表分析。
  - 开启慢日志，记录锁等待超时事务。

- **解决策略**：
  - 事务按固定顺序访问资源（如按主键升序）。
  - 缩短事务长度，减少锁持有时间。
  - 使用 `SELECT ... FOR UPDATE` 时尽量走索引，减少锁范围（行锁而非表锁）。
  - 适当降低隔离级别（如 `READ COMMITTED` 可减少间隙锁）。
  - 必要时通过 `KILL` 终止死锁事务。

---

## 五、常用 SQL 练习

> https://github.com/zljin/cheatsheet/tree/master/sql

### 1. 基础 DML（数据操作语言）

```sql
-- 插入
INSERT INTO `t1` (`col1`, `col2`) VALUES (val1, val2);

-- 更新（务必带 WHERE 条件）
UPDATE `t1` SET `col1` = val, `col2` = val WHERE `id` = 1;

-- 删除（注意备份）
DELETE FROM t1 WHERE col1 = val;

-- 清空表（重置自增 ID）
TRUNCATE TABLE t1;  -- 比 DELETE 快，但不可回滚，且重置自增计数
```

### 2. SELECT 查询要点

```sql
-- 去重、排序、分页（注意分页偏移）
SELECT DISTINCT col1, col2
FROM t1
WHERE col1 LIKE 'AB%'          -- 前缀匹配可用索引
ORDER BY col1 DESC, col2 ASC
LIMIT 1, 3;                    -- 从第2行开始取3条（偏移从0开始）

-- 分组聚合（注意：SELECT 中非聚合字段必须在 GROUP BY 中出现）
SELECT col1, COUNT(1) AS num
FROM t1
WHERE col1 > 2
GROUP BY col1
HAVING num >= 2                -- 对分组结果过滤，此处能用别名（MySQL 允许）
ORDER BY num DESC;
```

### 3. 连接查询（JOIN）

```sql
-- INNER JOIN（只返回匹配行）
SELECT u.name, o.order_id
FROM users u
JOIN orders o ON u.id = o.user_id;

-- LEFT JOIN（返回左表所有行，右表无匹配则为 NULL）
SELECT u.name, o.order_id
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;
```

### 4. 子查询与 EXISTS

```sql
-- 子查询（效率一般）
SELECT name FROM users WHERE id IN (SELECT user_id FROM orders WHERE amount > 100);

-- EXISTS（效率更高，常用于判断存在性）
SELECT name FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.amount > 100);
```

---

## 六、补充常用运维命令

```sql
-- 查看当前连接数
SHOW PROCESSLIST;

-- 查看表状态
SHOW TABLE STATUS LIKE 't1';

-- 分析表（更新索引统计信息）
ANALYZE TABLE t1;

-- 优化表（整理碎片）
OPTIMIZE TABLE t1;

-- 查看事务隔离级别
SELECT @@transaction_isolation;

-- 设置隔离级别（会话级）
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

## 总结

- **表设计**：范式与反范式结合，平衡一致性与性能。
- **索引**：用好执行计划，避免失效场景，善用覆盖索引。
- **事务**：选择合适隔离级别，理解 MVCC 原理。
- **锁**：悲观锁适合高冲突，乐观锁适合低冲突；死锁排查需关注锁顺序和事务大小。
- **SQL 实践**：熟悉基础语法，注意查询效率。
