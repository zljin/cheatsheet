---
title: Https
date: 2021-02-07 12:00:45
tags:
  - TechBase
categories: devops
---

> 属于网络协议应用层，即第七层

## Https

## 对称加密和非对称加密
对称加密：用公钥(同一把钥匙加锁，同一把钥匙解锁) DES

非对称加密：把锁头比作公钥，钥匙比作私钥，服务器接受所有信息前，先用锁头上锁加密，即公钥加密。之后收到消息之后，用钥匙解开密码，即私钥进行解密。 RSA

> http+SSL/TLS = https (通过SSL/TLS将http明文传输时的信息加密)

工作流程：

1. 用户在浏览器客户端发起https请求
2. 服务器收到请求后，返回配置好的CA证书+公钥Pub给浏览器客户端
3. 浏览器客户端验证CA证书没问题后,生成一个随机Key,用来做对称加密，再通过公钥Pub将随机Key给加密
4. 服务器接收随机Key的密文，用私钥Private解密，得到客户端真正想要发送的随机Key
5. 服务端用客户端发送的随机Key，对要传输的http内容进行对称加密，返回给客户端
6. 客户端使用随机Key对称解密密文，得到http的数据明文
7. 后续https请求使用之前的随机Key进行对称加解密


![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/ca1.png?raw=true)

CA证书的数字签名可以解决中间人问题

1. CA颁发机构拥有自己的一对公钥和私钥
2. CA机构在颁发证书时，会对证书明文信息进行哈希
3. 再用私钥将哈希值加密，得到数字签名
4. 明文数据和数字签名Sig1组成证书发送给客户端
5. 客户端接收后，分开明文数据和Sig1
6. 客户端用用CA机构提供的公钥，将Sig1解签得到Sig2
7. 用证书声明的哈希算法对明文Text进行hash得到H
8. 如果H与Sig2相等，表示证书可信，没有被中间人篡改

CA证书是一条信任链，各级CA机构的私钥是绝对的私密信息，如果浏览器没有这个CA机构，或者不可信，那么客户端不接受服务端传回的证书，显示Https警告

## 给自己本地的JDK添加安全证书，即下游服务方的公钥

https://keystore-explorer.org/downloads.html

通过kse工具可打开.jks工具修改证书


## 输入URL 到页面加载过程

1、地址栏输入URL 
2、DNS 域名解析IP
3、请求和响应数据
4、建立TCP连接（3次握手）
5、发送HTTP请求
6、服务器处理请求
7、返回HTTP响应结果
8、关闭TCP连接（4次挥手）
9、浏览器加载，解析和渲染

## DNS解析流程

本地查找：浏览器缓存 → 系统 hosts 文件 → 本地 DNS 缓存
递归查询：本地 DNS 服务器向根域名服务器发起查询
迭代查询：根域名服务器返回顶级域（.com）地址 → 顶级域返回权威域名服务器地址
最终获取：权威域名服务器返回对应域名的 IP 地址
缓存返回：本地 DNS 服务器缓存结果并返回给客户端

## 网络七层协议图

![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/network1.png)

> 第七层协议应用层,如https、FTP

> 第五层协议会话层,如SSL

> 第四层协议传输层,如TCP、UDP

TCP 面向可靠传输，三次握手，四次挥手 (文件下载，网页访问)
UDP 不可靠，高效 (直播通话)

Java Socket编程
Socket提供了能操作TCP/IP的API接口. 一个Socket实例唯一代表一台主机上一个应用程序通信链路
Socket address(ip+port) 将数据资料传送到相应的进程和线程
Socket pairs(ip+port+protocoll) 进行两台主机的通信和数据传输的交换

