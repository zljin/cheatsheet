
https://juejin.cn/post/7238823745828405308?searchId=202502231026191D986D4D597D649A013C#heading-23


> 安装maven后替换settings.xml

> 设置idea maven vm option config可以跳过ssl 校验
```
-Daether.connector.https.securityMode=insecure
```

> 跑sonar
```
mvn clean test
mvn -X sonar:sonar -Dsonar.token={token}
```

## 实用场景

### 依赖范围管理

- compile：默认范围，适用于所有阶段(即编译时有效，运行时有效，测试时有效)
- provided：编译测试时有效，运行时无效，适用于运行时环境已经提供了该依赖，如servlet-api
- runtime：编译时无效，运行时有效，测试时有效，适用于运行时环境需要该依赖
- test：编译时无效，运行时无效，测试时有效，适用于测试时需要该依赖
- system：编译时有效，运行时有效，测试时有效，适用于本地jar包，需要指定路径
- import：导入其他项目的依赖，适用于pom文件中

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>2.1.8.RELEASE</version>
    <scope>test</scope><!--只针对测试环境有效，而编译环境、运行环境中，因为用不到单元测试，可以通过scope移除-->
</dependency>
```

### 工作原理

中央仓库(aliyun)---->(私服/远程)仓库(optional,nexus)---->本地仓库---->项目依赖


### 生命周期

> Maven的生命周期分为三个阶段：clean(清理)、default(核心功能)、site(报告)

```shell
mvn clean compile # 编译
mvn clean package # 打包
mvn package -DskipTests   # 跳过测试
mvn clean install # 打包到本地仓库
mvn clean deploy # 打包到私服仓库
```

### 聚合项目

> 一个项目中包含多个子项目，父项目中的pom文件中配置modules

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.zljin.gulimall</groupId>
    <artifactId>gulimall</artifactId>
    <version>0.0.1</version>
    <name>gulimall</name>
    <description>gulimall聚合项目</description>
    <packaging>pom</packaging> <!--父工程-->

    <modules>
        <module>gulimall-product</module>
        <module>gulimall-member</module>
        <module>gulimall-order</module>
        <module>gulimall-common</module>
        <module>gulimall-gateway</module>
    </modules>
</project>
```

> 统一管理依赖版本

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-alibaba-dependencies</artifactId>
            <version>2021.0.6.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>2021.0.8</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

> 属性配置

可自定义属性，也可使用内置属性

```xml
<properties>
    <spring.version>5.2.0.RELEASE</spring.version><!--自定义属性-->
</properties>

<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-aop</artifactId>
    <version>${spring.version}</version>
</dependency>
```

