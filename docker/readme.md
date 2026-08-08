## Dockerfile

> 由一系列命令和参数构成的脚本，这些命令应用于基础镜像并最终创建一个新的镜像
> 基础镜像：如Centos就是操作系统级别的镜像，如果要创建一个镜像那么这个镜像本身是要代操作系统的

|  命令 | 作用  |
|  ----  | ----  |
| FROM image_ name:tag  |定义了使用哪个基础镜像启动构建流程 |
| ENV key value | 设置环境变量(可以写多条) |
| RUN command |是Dockerfile的核心部分(可以写多条)|
|ADD source_dir/file dest_ dir/file |将宿主机的文件复制到容器内，如果是一个压缩文件， 将会在复制后自动解压|
|copy source_dir/file dest_ dir/file|与上面相同，只是不解压|
|WORKDIR path_ _dir| 设置工作目录|


## Docker-Compose

> 可以通过yml配置定义多个容器同时部署，而DockerFile一次只能部署一个容器,需额外安装
