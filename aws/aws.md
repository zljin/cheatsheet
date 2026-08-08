---
title: Aws
date: 2022-08-20 12:00:45
tags:
  - TechBase
categories: devops
---

> 最先进的公有云，云计算资源

## doc

> <https://docs.aws.amazon.com/>

## aws基础知识

> <https://aws.amazon.com/cn/getting-started/fundamentals-core-concepts/>

> <https://www.bilibili.com/video/BV1NJ411n7LB?p=4&vd_source=88f2d67f21120fbed5f365a6638870f5>

### summary

    aws基于五大支柱

    1. 安全性 
    ####IAM
        通过IAM policy 对主体(基于身份的策略) 操作 资源(基于资源的策略)进行管理
        你是否有权限做，和资源是否准你做
    ####网络安全
        VPC,安全组(防火墙)
    #### 数据加密
        ssl(传输的加密)

    2. 性能效率
    3. 可靠性
    #### 故障隔离
        region,az 

    4. 卓越运营
    #### 基础设施即代码terraform,脚本管理infra

    #### 观测,可监控
        CloudWatch自定义指标收集
    5. 成本优化
    按量付费


    计算服务：
    1. ec2
    2. ecs
    3. auto scaling
    4. elastic load balancing
    5. eks

    存储服务:
    1. s3

    网络服务:
    1. VPC (endpoint)
    2. VPN
    3. DirectConnect
    4. CloudFront CDN

    数据库服务：
    1.RDB

    无服务：不需要管理底层的操作系统，依赖环境，我们只需要写好我们语言的代码
    ，然后上传我们的代码到无服务的产品，之后执行代码存放到对应的数据库中
    代表是Aws lambda

## VPC创建私有网络

> <https://www.bilibili.com/video/BV1wk4y1r7gX?spm_id_from=333.999.0.0&vd_source=88f2d67f21120fbed5f365a6638870f5>

#### step follow

    1. 在一个region中创建一个VPC,设置cidr为10.1.0.0/16
    tip:vpc自带本地路由,vpc内的子网都可通过本地路由进行访问


    cidr:基于子网掩码的方式,进行ip分配
    10.1.0.0/16  --16代表子网掩码,指前面16位不变


    2. 在此的VPC中创建三个子网，并定义子网的cidr网段和可用区域
    https://docs.aws.amazon.com/zh_cn/vpc/latest/userguide/VPC_Scenario1.html

    公有子网 inner-public  10.1.0.0/24
    私有子网,但可以访问互联网 inner-private & public  10.1.1.0/24
    私有子网 inner-private 10.1.2.0/24

    3. 在此vpc中创建互联网网关，作为互联网的出入口

    4. 创建NAT网关

    NAT:网络地址转换,将私网ip通过nat网络地址转换为公有的ip进行互联网访问(家庭路由器)

    NAT路由器:它至少有一个有效的外部全球IP地址，所有使用本地地址的主机在和外界通信时，
都要在 NAT 路由器上将其本地地址转换成全球 IP 地址。将私网ip通过nat转换为公有的ip进行互联网访问
通过NAT让外网连入内网，通过DHCP动态分配ip

    必须在公有子网创建

    5. 设置路由

        a. 首先创建公有子网的路由,
        先设置 0.0.0.0(互联网的所有请求) 都走刚刚创建的互联网网关 规则
        之后将创建好的公有子网路关联到公有子网中

            之后inner-public就有了访问外网的能力

        b. 再创建私有子网路由m通过nat实现内网访问外网   0.0.0.0--->nat

    6. 将你的ec2加入到你的vpc网段

![img](https://note.youdao.com/yws/api/personal/file/WEBe5489fd882c56dcb41dc44f81d1021bd?method=download\&shareKey=5d0d89badf256d5d2375ea7ec0b7c562)

## IAM

#### IAM introduce

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=9&spm_id_from=pageDriver&vd_source=88f2d67f21120fbed5f365a6638870f5>

what is IAM?

1.  IAM=Identity and Access Manager,(Global Service,no need to select region)
2.  Root account created by default,shoudn't be used or shared
3.  Users are people within your organization,and can be grouped
4.  Groups only contain users,no other groups
5.  user can belong to multiple groups or without any group

what is IAM\:Permissions

1.  Users or Groups can be assigned JSON document called policies,it's describe what a user is allowed to do
2.  these policies define the permissions of the users
3.  In Aws apply least privilege principle

#### IAM policies

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=10&vd_source=88f2d67f21120fbed5f365a6638870f5>

In group,IAM policies inheritance can make users inheritance by group

inline policy is used to one user without group

IAM policy sample and structure:

    {
      "Version": "2012-10-17",
      "Id": "S3-Account-Permissions"
      "Statement": [
        {
          "Sid": "1",
          "Effect": "Allow",
          "Principal":{
            "AWS": ["arn:aws:iam::123456789012:root"]
          },
          "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Resource": "arn:aws:s3:::productionapp/*"
        }
      ]
    }

#### IAM security

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=12&vd_source=88f2d67f21120fbed5f365a6638870f5>

1.  you can setup a password policy

2.  MFA=Multi Factor Authentication
    MFA=password you know + security device you own(
    Virtual MFA deviced such as google authenticator to create a device token
    )

#### IAM AWS Access key

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=14&vd_source=88f2d67f21120fbed5f365a6638870f5>

how can user access access?

1.  Aws web console use by password+MFA
2.  aws cli used by accesskey
3.  sdk used by accesskey

aws access key is security,don't share

#### IAM Roles for Service

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=20&vd_source=88f2d67f21120fbed5f365a6638870f5>

IAM role are secure way to grant permissions to entities that you trust.
for instance,Application code running on an ec2 instance that needs to perform actions on Aws resources

add IAM ROle into ec2 sample video

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=37&vd_source=88f2d67f21120fbed5f365a6638870f5>

#### IAM Security Tools

> audit
> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=23&vd_source=88f2d67f21120fbed5f365a6638870f5>

IAM Credentials Report(account level):
list all account's user and the status of their various credentials

IAM Access Advisor(user level):
show the user service permissions and lasted access date
revice your policies

#### IAM Best practice and summary

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=24&vd_source=88f2d67f21120fbed5f365a6638870f5>

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=25&vd_source=88f2d67f21120fbed5f365a6638870f5>

Users Groups Policies Roles Security Access Key Audit

## EC2

> 云中的弹性 虚拟服务器

#### Overview

how to create ec2? it's very important

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=28&vd_source=88f2d67f21120fbed5f365a6638870f5>

security Group is used to firewall in ec2,it's can control inbound or outbound traffic

ssh can login in ec2 inner
ssh -i Ec2.pem ec2-user\@35.180.242.162
or user Session manager in web console

#### EC2 instance roles

if you ec2 want to use aws command,it should add roles by IAM role policy

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=37&vd_source=88f2d67f21120fbed5f365a6638870f5>

#### private IP,public IP,Elastic IP

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=41&vd_source=88f2d67f21120fbed5f365a6638870f5>

```
public ip:
  it's means the machine can be identified on the internet
  it's unique across the whole web
  geo-located easily

private ip:
  it's mean the machine can only be identified on a private network only
  it's unique across the private network
  machine connect to www using a NAT+internet gateway(a proxy)
  Only a specify range of ips can be used as private ip

elastic ip:
  please avoid this way,instead,you can use a ramdom public ip and register dns name to it

when you destory you ec2 instance,you public ip will renew and change.if you want to unchange your public ip,you can use elastic ip,it's stable

```

#### EC2 placement Groups

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=43&vd_source=88f2d67f21120fbed5f365a6638870f5>

设置ec2安放在那里，虽然我们不能直接操作机架，但aws提供了策略给我们选择，that strategy can be defined using placement groups

#### ENI\:Elastic network interface

可以理解为ec2的网卡如eth0,一台ec2可以建很多网卡,且网卡可以迁移到其他ec2中
方便容灾处理的时候，网络访问迁移,ifconfig查看网卡信息

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=45&vd_source=88f2d67f21120fbed5f365a6638870f5>

    1. Logical component in a VPC that represents a vitual network card
    2. ENI have this attribute:
        primary private ipv4 or more secondary ipv4
        one elastic ip per private ipv4
        one public ipv4
        one or more security group
        A MAC address
    3. you can create ENI independently and attach them on the fly(move them) on ec2 instance for failover(故障迁移)
    4. bound to a specfic az

#### ec2 hiberate

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=47&vd_source=88f2d67f21120fbed5f365a6638870f5>

如果销毁ec2,内存数据和磁盘数据都会销毁，我们可以用EBS来保存磁盘数据，用hiberate恢复内存的数据，此数据也保存在磁盘中，后面直接提取

#### ec2 adcvanced Concepts

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=49&vd_source=88f2d67f21120fbed5f365a6638870f5>

vcpu\:each thread is represented as a virtual CPU

## EBS

> <https://docs.aws.amazon.com/zh_cn/ebs/?id=docs_gateway>

## EFS

> <https://docs.aws.amazon.com/zh_cn/efs/?id=docs_gateway>

## Elastic Load Balancing

> <https://docs.aws.amazon.com/zh_cn/elasticloadbalancing/index.html>

## Auto Scaling Group(ASG)

> <https://docs.aws.amazon.com/zh_cn/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html>

### overview

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=77&vd_source=88f2d67f21120fbed5f365a6638870f5>

```
ASG可以随着流量的多少，动态扩展ec2实例或者减少ec2实例
ASG in aws
  minimun count(scaling in)
  desired count
  max count(scalling out)

扩展实例时会自动加到ELB中

ASG have these attributes
  1. A launch configuration
    AMI+Instance type/EC2 user data/EBS/sg/ssh key pair

  2. min/max size,initial capacity

  3. network+subnet information

  4. loadbalaner information

  5. scaling policy

auto scaling alarm by metrics you define
if your ec2 unhealthy the asg will terminal it and create new instance

```

### hands on

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=78&vd_source=88f2d67f21120fbed5f365a6638870f5>

## S3

> 对象存储服务

### overview

    Buckets:
    存储桶是对象的容器，s3 object = 具体文件内容+文件的metadata 
    1. S3 allows people to store objects(file) in "buckets" (directories)
    2. Buckets must have a globally unique name and defined at the region level

    Objects:
    1. objects(file) have a key,the key is the full path
      s3://my-bucket/(my_file.txt)
      s3://my-bucket/(my_folder/another_folder/my_file.txt)
      the key is composed of prefix + object name
      prefix: my_folder/another_folder
      object name: my_file.txt

    ！！！注意s3没有目录的概念，只有key的概念

    2. object values are the content of the body (unlimit 5TB)
    3. metedata: this is information onto your object
    4. tags
    5. version id


    1. Amazon S3 Access Points are named network endpoints with dedicated access policies that describe how data can be accessed using that endpoint

### hands on

1.  how to create bucket

> <https://docs.aws.amazon.com/zh_cn/AmazonS3/latest/userguide/creating-bucket.html>

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=120&vd_source=88f2d67f21120fbed5f365a6638870f5>

1.  S3 Security & Bucket policies

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=126&spm_id_from=pageDriver&vd_source=88f2d67f21120fbed5f365a6638870f5>

    So if your user through IAM is allowed to access your s3 bucket,but your bucket policy is explicitly denying,you can't access it.

    Support VPC Endpoints(for instance in vpc without www internet)

1.  S3 bucket website

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=127&vd_source=88f2d67f21120fbed5f365a6638870f5>

1.  IAM roles and policies hand on

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=131&vd_source=88f2d67f21120fbed5f365a6638870f5>

## Route 53

#### overview

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=93&vd_source=88f2d67f21120fbed5f365a6638870f5>

```
Route 53 is aws dns,is also a domain register and ablity to check the health of your resources

each record contain:

DomainName (example.com)
recordType (A(ipv4),AAAA(ipv6),CNAME(转发，alias更好)，NS)
  NS:Name service for the Hosted Zone
  Control how traffic is routed for a domain
  存放了ip集合和域名集合的服务器，可以响应在托管区域的dns查询

  什么是Hosted Zone?
  A container for records that define how to route traffic to a domain

  分为public和private Hosted Zone,第一个用在公网,第一个用在VPC中(私有网络)

value (1.1.1.1)
Routing policy (simple)
TTL (dns cache time to live)

```

#### hands on

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=94&vd_source=88f2d67f21120fbed5f365a6638870f5>

## ECS

### overview

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=191&vd_source=88f2d67f21120fbed5f365a6638870f5>

    1. ECS = elastic container service
    2. launch docker containers on aws

    there are two method to use ecs:
    1. ecs cluster dependent many ec2 instance insfrastration(Auto Scaling),and each ec2 instance need register to ecs cluster
    2. ecs cluster use fargate(serverless,faas,you don't care about infra,just to use send farget task)


    you should consider your ec2 instance to add role when your instance want to connect s3 or rdb.
    and each instance inner have ecs agent,it can register ecs sevice,push image by ecr service and send log to cloudwatch 

    fargate:
    you just send fargate task to run docker container,when you create one fargate task,it's also create eni at the same time 
    and you should care about vpc cidr bound can't useless

    ECS Data volumes use efs file system to share data

### hands on

how to create ecs fargate?

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=193&vd_source=88f2d67f21120fbed5f365a6638870f5>

## ECR

> aws image registry

## EKS

    1. EKS = elastic kubernetes service
    2. manage kubernetes clusters on aws
    3. it's an alternative to ECS,更加推荐用eks来管理docker容器

    k8s是开源的自动化部署，扩展，管理容器的应用系统

    4. EKS的两种模式
      eks supports EC2 if you want to deloy your worker nodes or Fargate to deploy serverless containers 

![img](https://note.youdao.com/yws/api/personal/file/WEB2959ca21775d60c3fa6db28c76a7c304?method=download\&shareKey=2cdf4dc259436ddcd7cea0ba8cb25593)

## aws SQS

> <https://docs.aws.amazon.com/zh_cn/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html>

## aws SNS

> <https://docs.aws.amazon.com/zh_cn/sns/latest/dg/welcome.html>

## aws lambda

> 是一项计算服务，可使您无需预置或管理服务器即可运行代码

### what is serverless

    Serverless is a new paradiam in which the developers don't have to manage servers anymore
    thet just deploy code,function(Function as a service)

### overview

virtual functions - no servers to manage

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=199&vd_source=88f2d67f21120fbed5f365a6638870f5>

### hands on

> <https://www.bilibili.com/video/BV1wR4y1F7YM?p=200&spm_id_from=pageDriver&vd_source=88f2d67f21120fbed5f365a6638870f5>



## Q&A 扫盲

AWS EIP是指Amazon Web Services（AWS）中的Elastic IP（弹性公网IP）。
Elastic IP（EIP）是AWS云平台提供的一种公网IP地址服务。在AWS的云计算环境中，当您创建一个虚拟机实例（比如EC2实例），它会自动被分配一个公网IP地址，用于让该实例能够通过互联网进行通信。但是，每次停止（Stop）并重新启动（Start）该实例时，它被分配的公网IP地址会发生变化，这可能会导致一些问题，比如您的应用程序的DNS记录失效或网络连接中断。
为了解决这个问题，AWS引入了Elastic IP。Elastic IP是一个固定的公网IP地址，您可以将其动态地映射到您的AWS账户下的任何一个已运行的实例。这样，当您重新启动实例或重新创建实例时，您可以保持相同的公网IP地址，而不会发生变化。
使用Elastic IP有几个优势：
undefined 保持固定的公网IP地址，方便您的应用程序或服务的稳定运行。
undefined 避免了公网IP地址变化带来的管理和配置问题。
undefined 您可以随时将Elastic IP从一个实例解绑并绑定到另一个实例，实现IP地址的无缝切换。
需要注意的是，AWS对每个账户免费提供一定数量的Elastic IP地址使用，但如果您超出了免费配额，可能会产生一定的费用。因此，在使用Elastic IP时，建议合理规划和管理，避免资源的浪费。


在Amazon Web Services（AWS）中，Security Groups（安全组）是一种用于控制EC2实例和其他一些AWS服务的网络访问的虚拟防火墙。它是AWS云环境中重要的网络安全功能之一。
每个EC2实例和其他一些AWS资源（例如RDS数据库实例）都与一个或多个安全组相关联。安全组规则定义了允许或拒绝来自特定IP地址范围、协议和端口的流量。
以下是一些安全组的关键特点：
undefined 入站流量控制：安全组规则用于控制进入EC2实例或其他AWS资源的流量。您可以定义允许或拒绝特定协议（如TCP、UDP、ICMP）和端口范围的流量。例如，您可以配置安全组允许HTTP（端口80）和SSH（端口22）流量进入您的EC2实例。
undefined 出站流量控制：安全组规则还可以控制从EC2实例或其他AWS资源流出的流量。默认情况下，出站流量是允许的，并且不需要特定的规则。但是，您可以根据需要定义出站规则，限制流量访问特定的目标。
undefined 动态更新：安全组的规则是动态更新的。如果您修改了安全组规则，更改将立即应用到相关联的实例，无需重启实例。
undefined 隐式拒绝：如果某个流量与任何安全组规则不匹配，AWS会采用隐式拒绝策略，即拒绝这种流量。因此，安全组默认情况下是非常严格的，只允许明确规定的流量。
undefined 支持多个安全组：一个EC2实例可以与一个或多个安全组相关联。当实例与多个安全组相关联时，将应用这些安全组的规则的并集。
通过合理配置安全组，您可以确保EC2实例和其他AWS资源只能与受信任的网络设备通信，从而提高应用程序和数据的安全性。这是AWS中网络访问控制的一个重要层面。

AWS Systems Manager（AWS 系统管理器）是亚马逊网络服务（AWS）中的一项服务，它提供了一套集中化的工具，用于帮助您管理和运行 AWS 中的资源和应用程序。AWS Systems Manager 提供了许多功能，以简化系统管理、自动化任务、确保安全性，并提高操作效率。以下是一些 AWS Systems Manager 的主要功能：
资源管理和配置管理： AWS Systems Manager 可以帮助您收集有关 EC2 实例和其他 AWS 资源的信息，并通过标签、组、目标等方式对资源进行组织和分类。您可以使用 Systems Manager 的配置管理功能确保资源符合预期的配置，并持续监视和调整配置。

自动化： Systems Manager 允许您自动化重复性任务和常见的运维工作。您可以创建和管理脚本，例如自动备份数据、安装软件更新、执行系统维护等。这有助于减少手动操作，降低人为错误的风险，并提高资源管理的效率。

会话管理： AWS Systems Manager 的会话管理功能允许您在不必共享密码或使用 SSH 密钥的情况下，安全地远程连接到 EC2 实例和其他支持的资源。这有助于简化远程维护和故障排除过程。

参数存储： Systems Manager Parameter Store 提供了一个安全的方式来存储和检索敏感数据，例如密码、API 密钥和配置数据。您可以在参数存储中存储这些值，并在需要时从应用程序或脚本中检索它们。

补丁管理： Systems Manager 可以帮助您管理 EC2 实例和虚拟机镜像的操作系统和应用程序的补丁。您可以使用 Systems Manager 自动检测并应用最新的安全更新，从而提高系统的安全性和稳定性。

运维中心： AWS Systems Manager 提供了一个集中式的运维中心，您可以在其中查看资源的状态、执行操作、获取监控和日志数据等。这样可以更轻松地跟踪资源的运行状况，并及时发现和解决问题。

总体而言，AWS Systems Manager 是一个强大的工具集，帮助您更轻松地管理和运维 AWS 资源，提高系统的安全性和稳定性，并提高运营效率。



AWS VPC (Virtual Private Cloud) Endpoint (VPCE) 是 Amazon Web Services (AWS) 中的一种服务，用于实现与 AWS 服务的安全、高可用连接，无需通过公共 Internet 进行访问。

传统上，当您使用 AWS 服务（如 Amazon S3、Amazon DynamoDB 等）时，您的 VPC 中的资源需要通过 Internet 网关或 NAT 网关访问这些服务。这可能引入安全风险，并且增加了数据传输的延迟。

AWS VPC Endpoint 解决了这个问题，它允许您将 VPC 与 AWS 服务进行直接连接，而无需通过 Internet。VPCE 是一种虚拟设备，位于您的 VPC 中，允许您安全地访问支持 VPCE 的 AWS 服务。

有两种类型的 VPCE：

Gateway Endpoint：用于连接支持 S3 和 DynamoDB 的 AWS 服务。它是一种路由器设备，提供了一个 IP 地址，您可以使用这个 IP 地址访问相应的 AWS 服务。

Interface Endpoint：用于连接支持大多数其他 AWS 服务的接口。它是一种虚拟网络设备，与 VPC 中的子网关联。每个 Interface Endpoint 会有一个私有 IP 地址，用于访问特定的 AWS 服务。

VPCE 可以帮助您实现以下目标：

增加安全性：由于流量不经过公共 Internet，因此降低了暴露在互联网攻击中的风险。
减少延迟：由于直接连接到 AWS 服务，因此可以减少数据传输的延迟。
简化网络配置：无需设置 Internet 网关或 NAT 网关，简化了网络配置和管理。
请注意，AWS 的服务和功能可能会随着时间的推移而变化，因此建议在使用 VPCE 之前查阅 AWS 官方文档以获得最新信息和最佳实践。



AWS VPC (Virtual Private Cloud) 是亚马逊网络服务（Amazon Web Services）中的一项核心功能，它允许您在 AWS 云中创建和配置一个私有的、隔离的虚拟网络环境。

在 AWS 上，VPC 可以看作是您自己的私有数据中心，您可以在其中运行各种云资源，例如虚拟机实例 (EC2)，数据库实例 (RDS)，负载均衡器 (ELB)，以及其他 AWS 服务。通过 VPC，您可以自定义网络拓扑、配置子网、路由表、安全组等，从而完全控制您的云基础设施。

VPC 的主要特点包括：

隔离性：每个 VPC 是隔离的，您可以在各个 VPC 之间创建逻辑隔离的网络环境，确保资源之间的互不干扰。

自定义网络配置：您可以根据需求创建自定义的 IP 地址范围（CIDR 块）、子网、路由表等，灵活地配置网络结构。

安全性：通过安全组和网络访问控制列表 (Network ACLs)，您可以定义允许或拒绝进出 VPC 的网络流量，以实现网络安全控制。

连接选项：VPC 提供了多种连接选项，例如 Internet 连接、VPN 连接和 Direct Connect 连接，使您可以与本地数据中心或其他 VPC 建立安全连接。

子网：VPC 可以划分为多个子网，每个子网可以关联到不同的可用区 (Availability Zone)，从而实现高可用性和容错性。

使用 AWS VPC 可以帮助您构建安全、灵活、高度可用的云基础设施，确保您的云资源能够按照您的需求进行管理和扩展。在创建 AWS 资源时，通常会选择一个特定的 VPC 来将这些资源放置在其中，以便它们能够相互通信并与外部网络进行连接。