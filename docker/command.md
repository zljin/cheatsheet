
> docker基础命令

```sh
docker --help
docker pull tomcat:7-jre7
docker rmi 镜像ID
docker images

docker run -di --name=Mytomcat -p 9001:8080  \
-v /usr/local/webapps:/usr/local/tomcat/webapps tomcat:7-jre7 \
--privileged=true

docker ps -a
docker stop/start/rm 容器ID

docker exec -it 容器ID /bin/bash 
docker run -it --entrypoint sh imageName:tag
docker cp 容器名称:容器目录/文件 本地文件名字
docker inspect 容器ID
docker logs 容器ID

# dockerFile 本地build image命令，读取当前目录的DockerFile
docker build -t='flashbuy-app' .  


# docker compose
docker-compose -f docker-compose.yml up -d # -d 后台启动 -f 指定文件，default: ./docker-compose.yml
docker-compose down
docker-compose ps
docker-compose h


# docker nexus

1.docker pull registry --拉取私有仓库镜像
2.docker run -di --name=registry -p 5000:5000 registry   --启动私有仓库
3.curl http://192.168.2.6:5000/v2/_calalog  --->  {"repostories:[]"} -- 私仓创建成功

## 下面将镜像上传至私有仓库
1. 修改daemon.json
vi /etc/docker/daemon.json
systemctl restart docker
(1)标记此镜像为私有仓库的镜像
docker tag jdk1.8 192.168.2.6:5000/jdk1.8
(2)上传标记的镜像
docker push 192.168.2.6:5000/jdk1.8
```