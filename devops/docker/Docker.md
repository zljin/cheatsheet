# Docker

> 一句话：**镜像** = 打包好的应用模板，**容器** = 镜像跑起来的实例。用 Dockerfile 写"怎么构建"，用 `docker run` 把镜像跑成容器。

## 一、核心概念

| 概念 | 解释 |
|---|---|
| 镜像 (Image) | 打包好的应用模板（只读），比如 openjdk:8、tomcat |
| 容器 (Container) | 镜像跑起来的实例，同个镜像可跑 N 个容器 |
| 仓库 (Registry) | 存镜像的地方：Docker Hub / 私有仓库 registry |
| Dockerfile | 构建镜像的脚本 |
| Compose | 用 YAML 一次编排多个容器 |

---

## 二、基础命令

```sh
docker --help

# 镜像
docker pull tomcat:7-jre7           # 拉镜像
docker images                       # 看本地镜像
docker rmi 镜像ID                   # 删镜像

# 容器：-d 后台 -i 交互 -t 终端端口 -p 宿主机端口:容器端口
docker run -di --name=Mytomcat -p 9001:8080 tomcat:7-jre7
docker run -di --name=myredis -v /usr/local/redis:/data redis:latest
#   -p 9001:8080  宿主机9001 → 容器8080  （访问 http://localhost:9001）
#   -v 宿主机目录:容器目录  挂载数据，容器删了数据还在
#   --privileged=true  容器内可能有权限问题加上

docker ps -a                    # 所有容器（加 -a 含已停止）
docker stop/start/rm 容器ID
docker exec -it 容器ID /bin/bash # 进容器
docker logs -f 容器ID             # 看日志（-f 实时跟随）
docker stats                     # 看容器 CPU/内存占用（查 Java 内存超了很有用）
docker system prune -f           # 清理无用镜像/容器/构建缓存（磁盘满了先跑它）
docker cp 容器:目录 本地路径     # 拷文件
docker inspect 容器ID            # 看容器详情（IP、挂载等）

# 本地构建镜像（读取当前目录 Dockerfile）
docker build -t flashbuy-app .
```

---

## 三、Dockerfile（构建镜像 5 条足矣）

```dockerfile
FROM openjdk:8                        # 基础镜像（必须有，放最顶）
COPY ./target/*.jar /data/app.jar     # 复制文件到容器内（不解压）
# ADD   同 COPY，但自动解压 tar 包
WORKDIR /data                         # 工作目录（启动后在此）
ENV JAVA_OPTS="-Xmx512m"              # 环境变量
RUN echo "build.sh"                   # 构建时执行命令
ENTRYPOINT ["java","-jar","app.jar"]  # 容器启动命令
```

完整 Java 示例见同目录 [`DockerFile`](./DockerFile)。

**两个 Java 项目建议：**
- 同目录放 `.dockerignore`，写 `target/ .git/ *.log`——否则 `docker build` 会把几百 MB 的构建产物塞进镜像
- 镜像瘦身用**多阶段构建**：第一阶段 maven 镜像打 jar，第二阶段只拿 `openjdk:8-jre` 放 jar，镜像能小一半以上

---

## 四、Docker Compose（一次编排多个容器）

- 场景：Kafka、ES、Redis 等中间件本地一键起，`Dockerfile` 一次只能跑一个，Compose 可以跑一组
- 结构：`services` 定义各容器，容器之间用 `服务名` 通信（如 `zookeeper:2181`）

```yaml
version: '3'
services:
  zookeeper:
    image: wurstmeister/zookeeper:latest
    ports:
      - 2181:2181
  kafka:
    image: wurstmeister/kafka:latest
    environment:
      KAFKA_ADVERTISED_HOST_NAME: kafka
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181   # 用服务名访问 zookeeper
    volumes:
      - ./docker.sock:/var/run/docker.sock
```

```bash
docker-compose up -d      # 后台启动（-f 指定文件，默认 ./docker-compose.yml）
docker-compose down       # 停止并删除
docker-compose ps         # 看容器状态
docker-compose logs -f    # 看所有服务日志
```

> 容器间通信：Compose 里用**服务名**互相访问（如 `zookeeper:2181`）；
> 但 `docker run` 手动起的容器默认互相看不见，需要先 `docker network create mynet`，
> 再各自加 `--network=mynet`，此时才能用容器名互访。

完整示例见 [`docker-compose.yml`](./docker-compose.yml)。

---

## 五、私有仓库（把镜像推到内网）

```bash
# 1. 启动仓库（监听 5000 端口）
docker run -di --name=registry -p 5000:5000 registry

# 2. 验证：访问 http://192.168.2.6:5000/v2/_catalog 返回列表即成功

# 3. 允许 http 推送：改 /etc/docker/daemon.json 后重启 docker
#    { "insecure-registries": ["192.168.2.6:5000"] }

# 4. 打标签 → 推送
docker tag jdk1.8 192.168.2.6:5000/jdk1.8
docker push 192.168.2.6:5000/jdk1.8
```