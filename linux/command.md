```
vi ~/.bashrc source ~/.bashrc  # 当前用户环境变量配置
env # 环境变量
uptime # 查看系统运行时间、用户数、负载
uname -a # 查看内核/操作系统/CPU信息的linux系统信息命令

# 文本监听检索关键字
tail -f 100 report-management.log | grep -C 5 "Keyword" 

# 文件查找
find ~ -iname "*java" 

# 文件备份

scp local_file remote_username@remote_host:remote_path
scp remote_username@remote_host:remote_file local_path

# 文件解压
tar zvxf jdk-8u201-linux-x64.tar.gz -C /usr/java/ 
tar zvcf file.tar.gz 1.txt 2.txt

# 磁盘空间不足问题

df -h # 从总体查看磁盘状态，看挂载点/ 看是否有可用空间
du -sh * # 查看当前路径下各个文件和目录的大小
ls -lht # 查看文件大小

# CPU 与内存使用率过高问题

top -d 2 # 实时显示进程信息 2s一次
top -Hp pid # 查看某个进程的线程信息,找到进程中耗时最大的线程tid
jps # 专门查看Java进程，找到pid
free -m # 查看内存使用情况


# 网络延迟问题

netstat -tnpa # 查看所有 tcp 连接的信息，包括进程号
netstat -n | awk '/^tcp/{++S[$NF]}END{for(a in 5) print a,S[a]}'   # 查看当前连接
ps -ef | grep pid # 查看相关进程信息 
nslookup www.bilibili.com # check dns

# curl

curl --help
-I # 只返回http status
-x # 代理访问
-X # 指定http method 访问
-k # 跳过证书验证
-v # 打印详细的通信信息
--cacert a.pem # 采用此证书

curl -x http://127.0.0.1:7890 https://google.com.hk # 代理访问
curl -I -X GET 'https://www.bilibili.com/'
curl -o a.html https://www.bilibili.com/ # output

# 查看服务

crontab -l # 自动任务
chkconfig –list | grep on  # 列出所有启动的系统服务程序
nohup java -Xms3g -Xmx3g -jar app.jar --spring.config.location=applications.yml &
```