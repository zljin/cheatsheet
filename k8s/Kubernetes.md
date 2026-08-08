---
title: Kubernetes
date: 2022-08-09 12:00:45
tags:
  - TechBase
categories: devops
---

> 容器编排引擎: 提供给容器化应用的集群部署和管理工具，以yaml配置文件定义集群架构的规范和最终状态，使k8s始终维持这个状态, 其中容器可以指定为[[Docker]]


# 核心特性

声明式配置：通过 YAML 定义期望状态，系统自动维护实际状态与期望状态一致

自动化编排：Pod 调度、故障恢复、滚动更新、自动扩缩容

服务发现与负载均衡：内置 DNS 和服务抽象，支持多种负载均衡策略

存储编排：支持多种存储后端，提供持久化存储抽象

配置和密钥管理：统一的配置和敏感信息管理机制

多租户支持：命名空间隔离、RBAC 权限控制、资源配额管理

# 核心概念

Pod: 最小部署单位，包含一个或多个容器(如Java应用+SideCar容器)，并共享网络/存储

Deployment: 管理Pod，实现滚动更新，回滚，扩缩容

Service: 暴露Pod的访问入口，支持负载均衡
    1. ClusterIp (默认，集群内部访问) 
    2. Nodeport (节点端口对外暴露) 
    3. LoadBalancer(云平台LB)

ingress: 
    1. ingress可以实现通过域名和路径去访问service，避免对外暴露端口，并进行负载均衡
    2. 以域名加端口的形式访问不同的service
  
ConfigMap: 可以存配置一些环境变量,如CA证书,数据库连接池

Secret: 一些重要数据,如密码,token等


# Java应用部署实例

## Ingress架构图

```
graph TD
    A[用户] -->|访问| B[Ingress]
    B -->|路由规则| C[Service]
    C -->|负载均衡| D[Pod 1]
    C -->|负载均衡| E[Pod 2]
    C -->|负载均衡| F[Pod 3]
    D -->|应用| G[Java 容器]
    E -->|应用| H[Java 容器]
    F -->|应用| I[Java 容器]
```


## 基础部署示例

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
spec:
  replicas: 2  # 保持2个副本以实现高可用
  selector:
    matchLabels:
      app: java-app  # 必须与模板中的标签匹配
  template:
    metadata:
      labels:
        app: java-app  # 重要：用于Service和Ingress选择
    spec:
      containers:
      - name: java-container
        image: your-private-registry/java-app:v1.0.0
        # IfNotPresent 仅本地没有镜像时才远程拉，Always 永远都是从远程拉，Never 永远只用本地镜像，本地没有则报错
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080  # 应用监听的端口
        
        # 环境变量配置
        env:
        - name: JAVA_OPTS
          value: "-Xmx512m"  # JVM参数配置
        
        # 资源限制（生产环境必须配置）
        resources:
          requests:
            cpu: "250m"    # 最小CPU请求
            memory: "512Mi" # 最小内存请求
          limits:
            cpu: "1"       # CPU使用上限
            memory: "1Gi"   # 内存使用上限
        
        # 健康检查（确保应用就绪）
        readinessProbe:
          httpGet:
            path: /actuator/health  # Spring Boot健康检查端点
            port: 8080
          initialDelaySeconds: 20  # 应用启动后等待时间
          periodSeconds: 5         # 检查间隔
          failureThreshold: 3      # 失败多少次标记为未就绪
        
        # 存活检查
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        
        # 挂载配置文件（可选）
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
      
      # 配置文件卷（可选）
      volumes:
      - name: config-volume
        configMap:
          name: app-config

---

# ======================
# 2. 应用配置文件（可选）
# ======================
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.properties: |
    # Spring Boot 配置示例
    spring.datasource.url=jdbc:mysql://db-service:3306/appdb
    logging.level.root=INFO
  # 可以添加更多配置文件...

---

# ======================
# 3. 服务暴露（ClusterIP Service）
# ======================
apiVersion: v1
kind: Service
metadata:
  name: java-app-service
spec:
  selector:
    app: java-app  # 必须匹配Deployment中的标签
  ports:
    - name: http
      protocol: TCP
      port: 80       # 集群内访问的端口
      targetPort: 8080 # 容器实际端口
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8080
  type: ClusterIP  # 内部服务类型

---

# ======================
# 4. Ingress 路由配置
# 这里假设使用Nginx Ingress Controller，并且已经安装好
# ======================
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: java-app-ingress
  annotations:
    # Nginx Ingress 控制器注解
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"  # 最大上传文件大小
    nginx.ingress.kubernetes.io/enable-cors: "true"     # 启用CORS支持
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, PUT, POST, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"    # 强制HTTPS重定向（如有TLS配置）
spec:
  # TLS配置（可选，生产环境推荐）
  # tls:
  # - hosts:
  #   - java-app.example.com
  #   secretName: tls-secret  # 需要提前创建证书Secret
  
  rules:
  # 选项1：使用域名访问
  - host: java-app.example.com  # 替换为你的域名
    http:
      paths:
      - path: /api(/|$)(.*)  # 路径匹配规则
        pathType: Prefix
        backend:
          service:
            name: java-app-service
            port:
              number: 80
```

## 部署和使用说明

```sh
# 执行
kubectl apply -f java-app.yaml 

# 检查Pod状态
kubectl get pods -l app=java-app

# 检查Service
kubectl get svc java-app-service

# 检查Ingress
kubectl get ingress java-app-ingress

# 获取Ingress IP地址
INGRESS_IP=$(kubectl get ingress java-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 临时添加hosts（如果使用域名）
echo "$INGRESS_IP java-app.example.com" | sudo tee -a /etc/hosts

# 测试访问
curl http://java-app.example.com/api/health

# 查看应用日志
kubectl logs -l app=java-app --tail=100

# 进入Pod调试
kubectl exec -it pod-name -c contain-name -- /bin/bash

# 查看Ingress配置
kubectl describe ingress java-app-ingress

# 扩容副本
kubectl scale deployment/java-app --replicas=5

# 更新镜像（滚动更新）
kubectl set image deployment/java-app java-container=your-new-image:v2.0
```

## 生产优化

1. 配置https (tls)

2. 添加监控指标（proetheus,appdynamic）


# service mesh

## 核心特性
1. 统一:采用一套服务治理机制,实现网格大统一
2. 简化:服务治理外置到边车处理(sidecar) (基础设施下沉---业务逻辑和逻辑治理框架解耦) (减少版本碎片和升级困扰)
3. 专注:只关心业务逻辑核心


![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/servicemesh1.png)

## 如何理解sidecar?

> 边车为逻辑治理框架，下面是特性

1. 可用性：故障注入,数据重放,重试,重定向,熔断,灰度发布(canary deploy)
2. 安全性: 传输加密,用户认证,服务授权
3. 可控性：前置检查,限流管理,遥测报告


## 灰度发布(服务发布的可用性)

![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/servicemesh2.png)

绿色为新版本服务,蓝色为上一版本的服务,可以配置Istio负载管理,控制流量流向的比例,分配到新上线的服务中,若1%分配后正常,则继续加大比例,这样上线用户就会无感知

## Istio负载管理

1. Virtual Service 虚拟服务 --- 客户视角
2. Destination Rule 目标规则  --- 资源视角
3. 两者结合形成内部网络管理

![](https://cdn.jsdelivr.net/gh/zljin/document/img/technical/servicemesh3.png)


## Istio Service Mesh 完整部署示例

> Istio Envoy Proxy组件 https://github.com/istio/istio
> https://github.com/istio/istio/tree/master/samples/bookinfo
> https://istio.io/latest/docs/examples/bookinfo/

```yml
# ==========================================
# 1. Namespace 配置（启用自动 Sidecar 注入）
# ==========================================
apiVersion: v1
kind: Namespace
metadata:
  name: java-app
  labels:
    # 关键：启用 Istio 自动注入
    istio-injection: enabled
---
# ==========================================
# 2. Java 应用部署（自动注入 Sidecar）
# ==========================================
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
  namespace: java-app
  labels:
    app: java-app
    version: v1.0  # 版本标签用于金丝雀发布
spec:
  replicas: 3
  selector:
    matchLabels:
      app: java-app
  template:
    metadata:
      labels:
        app: java-app
        version: v1.0
      # 注解确保 Sidecar 正确配置
      annotations:
        # 优化 Java 与 Envoy 的交互
        proxy.istio.io/config: |
          concurrency: 2
        # 资源限制
        sidecar.istio.io/resources: '{"limits":{"cpu":"200m","memory":"256Mi"}}'
    spec:
      containers:
      - name: java-container
        image: registry.example.com/java-app:v1.0.0
        ports:
        - name: http-web  # 必须含 http 前缀（Istio 要求）
          containerPort: 8080
        
        # JVM 优化配置
        env:
        - name: JAVA_OPTS
          value: "-XX:+UseContainerSupport -Xmx512m -Dserver.port=8080"
        
        # 健康检查（Istio 依赖）
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 20
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        
        # 资源限制
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "1"
            memory: "2Gi"
---
# ==========================================
# 3. Service 配置（关键连接点）
# ==========================================
apiVersion: v1
kind: Service
metadata:
  name: java-app-service
  namespace: java-app
spec:
  selector:
    app: java-app
  ports:
  - name: http  # 必须含 http 前缀
    protocol: TCP
    port: 8080
    targetPort: 8080
  # 注意：必须使用 ClusterIP
  type: ClusterIP
---
# ==========================================
# 4. Gateway（入口网关配置）
# ==========================================
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: java-app-gateway
  namespace: java-app
spec:
  selector:
    istio: ingressgateway # 使用默认的 Istio Ingress Gateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "java-app.example.com"  # 你的域名
    # 启用 HTTPS 只需添加如下配置：
    # - port:
    #     number: 443
    #     name: https
    #     protocol: HTTPS
    #   tls:
    #     mode: SIMPLE
    #     minProtocolVersion: TLSV1_2
    #     credentialName: java-app-tls-secret  # 证书 Secret
    #     cipherSuites: [ECDHE-RSA-AES256-GCM-SHA384,,,]
    #   hosts:
    #   - "java-app.example.com"
---
# ==========================================
# 5. VirtualService（流量路由规则）
# ==========================================
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: java-app-vs
  namespace: java-app
spec:
  hosts:
  - "java-app.example.com"  # 匹配 Gateway 的 hosts
  gateways:
  - java-app-gateway        # 绑定到我们的 Gateway
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: java-app-service.java-app.svc.cluster.local  # K8s 服务全名
        port:
          number: 8080
# ==========================================
# 6. DestinationRule（定义流量策略）
# ==========================================
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: java-app-dr
  namespace: java-app
spec:
  host: java-app-service.java-app.svc.cluster.local
  trafficPolicy:
    # 负载均衡策略
    loadBalancer:
      simple: LEAST_CONN  # 最少连接
    # 连接池设置（防止HTTP连接耗尽）
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    # 异常检测（自动熔断）
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  # 子集定义（用于金丝雀发布）
  subsets:
  - name: v1
    labels:
      version: v1.0
  - name: v2
    labels:
      version: v2.0
---
# ==========================================
# 7. 监控配置（Prometheus 指标抓取）
# ==========================================
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: java-app-metrics
  namespace: java-app
spec:
  workloadSelector:
    labels:
      app: java-app
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.wasm
        typed_config:
          "@type": type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                "@type": type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "metrics": [
                      {
                        "dimensions": {
                          "destination_cluster": "node.metadata['CLUSTER_ID']",
                          "source_cluster": "downstream_peer.cluster_id"
                        }
                      }
                    ]
                  }
              vm_config:
                runtime: envoy.wasm.runtime.null
                code:
                  local:
                    inline_string: "envoy.wasm.metadata_exchange"
---
# ==========================================
# 8. 金丝雀发布配置示例
# ==========================================
# 注意：需配合上面 DestinationRule 的 subsets
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: java-app-canary
  namespace: java-app
spec:
  hosts:
  - "java-app.example.com"
  gateways:
  - java-app-gateway
  http:
  - route:
    - destination:
        host: java-app-service.java-app.svc.cluster.local
        subset: v1
      weight: 90  # 90% 流量到 v1
    - destination:
        host: java-app-service.java-app.svc.cluster.local
        subset: v2
      weight: 10  # 10% 流量到 v2

```






# helm chart
> helm通过打包的方式，支持发布的版本控制，简化k8s资源应用部署
> https://artifacthub.io/
> https://helm.sh/zh/docs/intro/quickstart/
> https://www.cnblogs.com/lyc94620/p/10945430.html

1. helm可以类似于rpm的yum工具包，用户快速创建k8s资源，基于template的方式管理，将资源的具体spec value抽离出来

2. helm有网络仓库，在线安装直接链接安装，离线安装，通过下载源码然后连接公司局域网安装镜像

3. helm和k8s版本要兼容，helm run时，会自动读取kubectl的配置连接到你的eks (只推荐helm3)

4. chart安装包，release为安装后的实例


## helm cheat sheet

```
### 离线安装用的局域网镜像
helm install --debug coredns C:\java_idea\helm\coredns --namespace=kube-system -f C:\java_idea\helm\coredns\value.yaml
helm ls --all-namespaces
helm uninstall coredns -n=kube-system

## 在线安装
helm repo add coredns https://coredns.github.io/helm
helm --namespace=kube-system install coredns coredns/coredns
```


# reference

https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/9EX8Cp45

https://kubernetes.io/zh-cn/docs/concepts/

https://jimmysong.io/kubernetes-handbook/cloud-native/cloud-native-definition.html

