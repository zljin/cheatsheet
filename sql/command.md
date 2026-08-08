```sql
-- DDL

-- char(10) 固定占10个字符空间, varchar(10) 最多占10个字符空间
-- bigint(10) 在开启ZEROFILL后，前面自动补0
CREATE TABLE `t1` (
  `id` varchar(255) NOT NULL COMMENT '主键，自增ID',
  `col1` char(10) DEFAULT NULL,
  `col2` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- DML
insert into `t1` (`col1`, `col2`) values(val1, val2);
update `t1` set `col1` = val,`col2`=val where `id`= 1;
delete from t1 where col1 = val;
truncate TABLE t1; -- 清空数据并将索引所占空间初始化

-- DQL
select distinct col1, col2
from t1
where col1 like 'AB%'
order by col1 desc , col2 asc 
-- limit, 从第二行数据开始，返回三条数据
limit 1, 3; 

-- GROUP BY
-- 1. 除汇总字段外，select的每个字段都需在group by中给出            
-- 2. GROUP BY不支持可变长度的数据类型           
-- 3. NULL 的行会单独分为一组 
select col1, COUNT(1) AS num
from t1
where col1 > 2
group by col1 having num >= 2
order by num desc;

-- exists and in 
-- 1. in是在内存里遍历比较:相当于两个for循环,对内存需求高
select * from A where id in (select id from B);
-- 2. exists需要查询数据库:一个for循环,但每次都要IO查询,且in查询一般不走索引
select * from A where exists (select 1 from B where A.id=B.id);

-- JOIN

-- 内连接:等值连接,无条件语句下返回笛卡尔积
select * from t1 join t2 on t1.C=t2.C;
+---+---+---+---+---+---+
| A | B | C | C | D | E |
+---+---+---+---+---+---+
| 1 | 2 | 3 | 3 | 4 | 5 |
+---+---+---+---+---+---+

-- 外连接:返回左边所有的记录和右表中连接字段相等的记录
select t1.A,t1.B,t1.C,t2.D,t2.E from t1 left join t2 on t1.C=t2.C;
+---+---+---+------+------+
| A | B | C | D    | E    |
+---+---+---+------+------+
| 1 | 2 | 3 |    4 |    5 |
| 5 | 6 | 7 | NULL | NULL |
+---+---+---+------+------+


-- 窗口函数
ROW_NUMBER() OVER (
    PARTITION BY 分组字段 
    ORDER BY 排序字段
)
```