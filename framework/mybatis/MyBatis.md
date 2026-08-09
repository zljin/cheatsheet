---
title: MyBatis
date: 2021-02-22 14:00:00
tags:
  - TechBase
categories: Frameworks
---

> 方便Java程序操作数据库的一种ORM框架的


## sample use

```xml
    <resultMap id="ExtListBaseResultMap" type="com.xy.tms.tran.entity.vo.TranSeaPlanListVo"
               extends="com.xy.tms.tran.dao.TranSeaPlanMapper.BaseResultMap">
        <result column="sea_plan_detail_id" jdbcType="BIGINT" property="seaPlanDetailId"/>
        <result column="ship_company_order_no" jdbcType="VARCHAR" property="shipCompanyOrderNo"/>
        <result column="materiel_code" jdbcType="VARCHAR" property="materielCode"/>
        <result column="materiel_name" jdbcType="VARCHAR" property="materielName"/>
        <result column="materiel_id" jdbcType="BIGINT" property="materielId"/>
        <result column="status" jdbcType="VARCHAR" property="status"/>
        <result column="create_by" jdbcType="VARCHAR" property="createBy" />
        <result column="create_by_name" jdbcType="VARCHAR" property="createByName" />
        <result column="create_time" jdbcType="TIMESTAMP" property="createTime" />
        <result column="update_by" jdbcType="VARCHAR" property="updateBy" />
        <result column="update_by_name" jdbcType="VARCHAR" property="updateByName" />
        <result column="update_time" jdbcType="TIMESTAMP" property="updateTime" />
        <collection property="sysRoleIdList" javaType="java.util.ArrayList" ofType="java.lang.String" resultMap="itemResultId"/>
    </resultMap>

    <resultMap id="itemResult" type="java.lang.String">
        <id column="role_name" javaType="java.lang.String" jdbcType="VARCHAR" property="role_name"/>
    </resultMap>

    <sql id="Base_Column_List">
        tran_main_plan_id, organization_id, tran_order_id, tran_main_plan_no, plan_sort,
        tran_type, tran_type_desc, tran_method, tran_method_desc, start_station_id, end_station_id,
        audit_status, audit_status_desc, audit_time, audit_user, allot_status, allot_status_desc,
        delivery_status, delivery_status_desc, remark, create_by, create_by_name, create_time,
        update_by, update_by_name, update_time, version
     </sql>

    <select id="querySeaPlan" parameterType="com.xy.tms.tran.entity.vo.TranSeaPlanQueryVo"
            resultMap="ExtListBaseResultMap">
        SELECT
        <include refid="Base_Column_List" />
        tsp.sea_plan_id sea_plan_id,
        tsp.status_desc status_desc, -- 状态,
        tsp.sea_plan_no sea_plan_no, -- 海运计划号,
        tsp.ship_company_order_no ship_company_order_no, -- 船公司订舱单号
        tsp.book_space_success_flag_desc book_space_success_flag_desc, -- 是否订舱成功,
        tsp.plan_date plan_date, -- 计划日期,
        tspd.materiel_code materiel_code, -- 物料编码,
        tspd.materiel_name materiel_name, -- 物料名称,
        CONCAT(ifnull(mm.materiel_spec,'')
        ,ifnull(mm.packing_weight_unit_desc,''),'/',ifnull(mm.packing_pieces_unit_desc,'')) as packing_spec_full_desc,
        -- 规格,
        pg.product_grade_name product_grade_name, -- 等级,
        mm.base_unit_desc base_unit_desc, -- 单位
        tspd.product_grade_id
        FROM tran_sea_plan tsp
        LEFT JOIN tran_sea_plan_detail tspd ON tsp.sea_plan_id = tspd.sea_plan_id
        LEFT JOIN mst_warehouse start_mw ON start_ml.location_id = start_mw.location_id
        AND start_mw.organization_id = tsp.organization_id
        LEFT JOIN mst_carrier mc ON tsp.ship_company_id = mc.carrier_id
        <where>
            <trim prefixOverrides="and">
           <!-- <trim prefix="WHERE" prefixOverrides="AND">  与上面等价 -->
                <if test="queryVo.seaPlanNo != null and queryVo.seaPlanNo != ''">
                    AND tsp.sea_plan_no LIKE concat('%',#{queryVo.seaPlanNo}, '%')
                </if>
                <if test="queryVo.organizationId != null and queryVo.organizationId != ''">
                    AND tsp.organization_id = #{queryVo.organizationId}
                </if>
                <if test="queryVo.status != null and queryVo.status.size() >0">
                    AND tsp.status IN
                    <foreach collection="queryVo.status" item="item" open="(" separator="," close=")">
                        #{item}
                    </foreach>
                </if>
                <if test="queryVo.createTimeList != null and queryVo.createTimeList.size() == 2">
                    AND tsp.create_time
                    BETWEEN #{queryVo.createTimeList[0] } AND #{queryVo.createTimeList[1]  }
                </if>
                <choose>
                    <when test="isUpdate !=null ">
                        AND tsp.create_time = #{isUpdate, jdbcType=INTEGER}
                    </when>
                    <when test="isDelete != null">
                        AND tsp.create_time  = #{isDelete, jdbcType=INTEGER}
                    </when>
                    <otherwise>
                        AND tsp.create_time NOT NULL
                    </otherwise>
                </choose>
                <if test="userName != null and userName != ''">
                    <bind name="userNameLike" value="'%' + userName + '%'"/>
                    and username like #{userNameLike}
                </if>　　
            </trim>
        </where>
        ORDER BY
        tsp.sea_plan_no DESC
    </select>

    <update id="updateAuthorIfNecessary">
      update Author
        <set>
          <if test="username != null">username=#{username},</if>
          <if test="password != null">password=#{password},</if>
          <if test="email != null">email=#{email},</if>
          <if test="bio != null">bio=#{bio}</if>
        </set>
      where id=#{id}
    </update>

    <update id="updateAuthorIfNecessary2">
      update Author
        <trim prefix="SET" suffixOverrides=",">
            <if test="username != null">username=#{username},</if>
                <if test="password != null">password=#{password},</if>
                <if test="email != null">email=#{email},</if>
                <if test="bio != null">bio=#{bio}</if>
        </trim>
      where id=#{id}
    </update>
```

## 什么是ORM

> 对象关系映射，将javaBean对象与关系型数据库表映射的技术

mybatisplus: 
1、半开ORM，能够对[[MySQL]]控制灵活
2、强大的插件机制

MyBatis 设计了完善的插件体系，允许开发者通过拦截器接口扩展或修改 MyBatis 的核心行为。
常见的应用包括分页插件、审计日志、性能监控等，大大增强了框架的可扩展性。

jpa: 可以兼容适配多种数据库，包括非关系型数据库

## 你是如何设置数据库主键自增的
1、单机高并发可用自增ID
2、分布式系统要确定唯一性建议雪花算法

```java
mybatis-plus:
  global-config:
    db-config:
      id-type: ASSIGN_ID # 主键生成策略，ASSIGN_ID通常配合雪花算法使用
      
@TableName(value ="order_info")
@Data
public class OrderInfo {
    /**
     * 订单主键
     */
    @TableId(value = "id")
    private String id;
    
 }
```


## 如何实现字段映射的
1、ResultMap，(select user_name as userName) 隐式转换，驼峰命名自动转换，实现数据库列于Java对象属性的字段映射
2、association 和 collection 标签提供了处理一对一和一对多关系
3、TypeHandler处理 Java 类型和 JDBC 类型之间的转换，如日期格式DateTypeHandler

## 如何实现关联查询

```xml
<!-- StudentMapper.xml -->
<resultMap id="studentWithClassMap" type="Student">
    <id property="id" column="id"/>
    <result property="name" column="name"/>
    
    <!-- 一对一关联：一个学生属于一个班级 -->
    <association property="clazz" javaType="Class">
        <id property="id" column="class_id"/>
        <result property="className" column="class_name"/>
    </association>
    
    <!-- 一对多关联：一个学生有多个成绩 -->
    <collection property="scores" ofType="Score">
        <id property="id" column="score_id"/>
        <result property="courseName" column="course_name"/>
        <result property="score" column="score"/>
    </collection>
</resultMap>

<!-- 关联查询SQL -->
<select id="getStudentWithClassAndScores" resultMap="studentWithClassMap">
    SELECT 
        s.id,
        s.name,
        c.id as class_id,
        c.name as class_name,
        sc.id as score_id,
        sc.course_name,
        sc.score
    FROM student s
    LEFT JOIN class c ON s.class_id = c.id
    LEFT JOIN score sc ON s.id = sc.student_id
    WHERE s.id = #{id}
</select>
```

## `#`和$的区别是什么

1、#{} 是参数占位符，有效防止 SQL 注入攻击
2、${}是字符串替换，存在 SQL 注入风险，常用于动态表名，动态列名，原生数据库函数等


## mybatis插件运行原理

1、实现Mybatis的Interceptor接口。
2、通过@Intercepts 注解声明要拦截的目标
3、实现intercept方法
4、注意插件的执行顺序

举例：PaginationInnerInterceptor（分页插件），慢查询性能监控插件（拦截Executor 的 query 和 update 方法，记录 SQL 执行时间和参数）


MyBatis 插件的运行原理是基于动态代理和责任链模式实现的。
本质上，MyBatis允许我们在 SQL 执行的关键点插入自定义逻辑，从而实现功能扩展。
MyBatis 提供了四个关键拦截点：
1、Executor：负责整体的 SQL 执行流程，包括创建缓存和事务管理
2、ParameterHandler：负责 SQL 参数的处理和设置
3、ResultSetHandler：负责结果集的映射和处理
4、StatementHandler：负责语句的准备和执行


## 如何实现动态查询

写mybatis时加动态标签如if,where等，可以提高灵活性

```yml
<select id="searchProducts" resultType="Product">
SELECT * FROM product
<where>
    <if test="categoryId != null">category_id = #{categoryId}</if>
    <if test="minPrice != null">AND price >= #{minPrice}</if>
    <if test="maxPrice != null">AND price<= #{maxPrice}
    </if>
    <if test="brands != null and brands.size > 0">
        AND brand IN
        <foreach collection="brands" item="brand" open="(" separator="," close=")">
            #{brand}
        </foreach>
    </if>
</where>
```


## 如何实现分页

1、使用原生分页  limit 1,3
2、使用mybatis PageHelper分页插件
3、使用mybatis-plus 内置分页插件PaginationInnerInterceptor
https://baomidou.com/plugins/pagination/

## MyBatis-plus有什么用
在MyBatis 的基础上提供了更多简化开发，且只做增强不做改变。

主要的特点：
1、继承 BaseMapper 接口，内置通用 CRUD 操作
2、提供了 QueryWrapper 和LambdaQueryWrapper，使复杂查询条件的构建变得简单而类型安全
3、内置了分页插件
4、提供IDEA插件MyBatisX 代码生成器

简单查询用QueryWrapper，复杂查询请直接去xml写sql


## MyBatis用什么连接池

一般集成第三方连接池如HikariCP（适合高并发），由Spring管理连接池，注入到MyBatis的SqlSessionFactory中


## MyBatis缓存机制

可以减少数据库访问次数

分为一级缓存和二级缓存，
一级缓存sqlSession级别的缓存，默认开启无法关闭
（当执行查询时，MyBatis 会先检查一级缓存中是否存在相同的查询请求（通过 SQL 语句、参
数、分页等信息生成的缓存键），如果存在则直接返回缓存结果，不再访问数据库）

二级缓存是mapper级别的缓存，默认关闭，共享sqlSession的一级缓存，在分布式场景可能会导致数据一致性问题，谨慎使用，用redis