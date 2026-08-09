# Kubernetes

> 容器编排引擎：用 YAML 声明"期望状态"，K8s 自动让集群一直保持这个状态。容器可用 [[Docker]]

---

# 一、核心概念（实战只需要这几个）

| 概念 | 一句话解释 | 实战用途 |
|---|---|---|
| Pod | 最小部署单元，装容器（一般 1 个） | 不用管里面细节 |
| Deployment | 管理一组 Pod | 滚动更新 / 回滚 / 扩缩容 |
| Service | Pod 的固定访问入口，内部负载均衡 | Pod IP 会变，Service 不变 |
| Ingress | 按域名+路径转发访问 | 对外暴露，不用开一堆端口 |
| ConfigMap | 存非敏感配置（env、配置文件） | 和代码解耦 |
| Secret | 存敏感信息（密码、Token、证书） | 用法同 ConfigMap |

**两个易混点：**
- Deployment 管"怎么跑"（几个副本、镜像版本、健康检查）；Service 管"怎么访问"（流量分发给哪些 Pod）。
- 也可以用一句理解：Service 是 Deployment 的门面，Ingress 是 Service 的门口。

**Service 三种类型（一般记住两种就够）：**
- ClusterIP（默认）：只能集群内访问，内部服务间调用
- NodePort：映射到节点端口，`节点IP:端口` 可外部访问，测试用
- LoadBalancer：交给云平台 LB（生产常用）

---

# 二、Java 应用部署实战（照抄就能用）

一个文件搞定：Deployment + ConfigMap + Service + Ingress，直接 `kubectl apply`。

## 1. Deployment（应用本体）

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
spec:
  replicas: 2                # 副本数
  selector:
    matchLabels:
      app: java-app
  template:
    metadata:
      labels:
        app: java-app         # ✍️ 最重要：Service 靠它找到 Pod
    spec:
      containers:
      - name: java-container
        image: your-registry/java-app:v1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: JAVA_OPTS
          value: "-Xmx512m"

        # 生产必须配：请求(下限)/限制(上限)
        resources:
          requests: { cpu: "250m", memory: "512Mi" }
          limits:   { cpu: "1",    memory: "1Gi" }

        # 就绪探针：没就绪前不接流量（Spring Boot 直接用它）
        readinessProbe:
          httpGet: { path: /actuator/health, port: 8080 }
          initialDelaySeconds: 20
          periodSeconds: 5
          failureThreshold: 3
        # 存活探针：挂掉自动重启
        livenessProbe:
          httpGet: { path: /actuator/health, port: 8080 }
          initialDelaySeconds: 30
          periodSeconds: 10
```

## 2. ConfigMap（应用配置，可选）

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.properties: |
    spring.datasource.url=jdbc:mysql://db-service:3306/appdb
    logging.level.root=INFO
```

> 给应用注入配置的两种方式（上面 Deployment 记得加才生效）：
> - **环境变量**：Deployment 容器里加 `envFrom: [{ configMapRef: { name: app-config } }]`
> - **挂成文件**：Deployment 的 `volumes` 挂 ConfigMap，再 `volumeMounts` 到 `/app/config`（建议用这个，改动不用重新打包镜像）

## 3. Service（内部入口）

```yml
apiVersion: v1
kind: Service
metadata:
  name: java-app-service
spec:
  selector:
    app: java-app               # 指向 Deployment 的 label
  ports:
  - port: 8080                  # Service 端口（外部/Ingress 引用它）
    targetPort: 8080            # 容器实际端口
  type: ClusterIP
```

## 4. Ingress（域名访问）

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: java-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: java-app.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: java-app-service
            port: { number: 8080 }
```

**本地没有 DNS 时测域名：把 Ingress IP 绑到 hosts**

```sh
INGRESS_IP=$(kubectl get ingress java-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$INGRESS_IP java-app.example.com" | sudo tee -a /etc/hosts
curl http://java-app.example.com/api/xxx
```

## 5. 常用命令速查

### 发布

```sh
kubectl apply -f java-app.yaml                # 发布 / 更新
kubectl apply -f java-app.yaml -v=8           # 加 -v 看调试日志排查报错
# 先让 kubectl 生成模板再改，避免手写 YAML
kubectl create deployment java-app --image=java-app:v1 --dry-run=client -o yaml > deploy.yaml
```

### 查看

```sh
kubectl get pods,svc,ingress,cm,secret -A     # -A 所有命名空间
kubectl get pods -n <namespace>                # -n 指定命名空间（K8s 的"隔离分区"）
kubectl get pods -o wide                      # 看 Pod IP 和所在节点
kubectl describe pod <pod-name>               # 排查问题先看它（事件）
kubectl logs -l app=java-app --tail=100       # 看日志（加 -f 跟随）
kubectl exec -it <pod-name> -c <container> -- /bin/bash
kubectl port-forward svc/java-app-service 8080:8080  # 本地直接连集群内服务（调试神器）
```

### 扩容 / 更新 / 回滚

```sh
kubectl scale deployment/java-app --replicas=5
kubectl set image deployment/java-app java-container=your-image:v2
kubectl rollout restart deployment/java-app    # 仅重启不换镜像
kubectl rollout status deployment/java-app     # 查看更新进度
kubectl rollout undo deployment/java-app       # 回滚到上一个版本
kubectl rollout history deployment/java-app    # 版本历史
```

### 排查链路（状态 → 事件 → 日志 → 进容器）

```sh
kubectl get pods -o wide                   # 1) 看状态（Pending/CrashLoop 最常见）
kubectl describe pod <pod-name>            # 2) 看事件和原因
kubectl logs -l app=java-app --tail=200    # 3) 看日志（Java 崩溃基本在这）
kubectl exec -it <pod-name> -- /bin/bash   # 4) 进容器调试
```

> 能出网的关键：`Service → targetPort(容器端口) → 应用监听端口`，三处必须一致。

## 6. 生产补充（遇到再查细节）

- **私有镜像仓库**：Deployment 里加 `imagePullSecrets` 才有权限拉镜像（你有 docker 私仓就会遇到）
- **DB / ES / Kafka 等有状态服务**：裸用 Deployment 装数据会丢，要么放 K8s 外，要么用 `PV/PVC + StatefulSet`
- **自动扩容**：配完 `requests` 后上 HPA，按 CPU 自动扩缩

---

# 三、Helm（类似"K8s 的 apt/yum"）

- 把多个 YAML 打包成一个 Chart，`values` 抽离可变配置，一套模板发不同环境
- `Chart` = 部署包，`Release` = 安装后的实例（同名 chart 可装多个 release）
- 推荐 Helm 3，直接读 kubeconfig，无需 Tiller

```sh
helm repo add coredns https://coredns.github.io/helm
helm install coredns coredns/coredns --namespace=kube-system
helm ls --all-namespaces
helm uninstall coredns -n kube-system
# 离线：把 Chart 源码下载后引私有仓库镜像
helm install --namespace=kube-system coredns ./coredns -f value.yaml
```

---

# 四、Service Mesh（了解即可）

> 把原来 **嵌入到业务代码里的服务治理**（熔断、限流、鉴权、灰度）抽出来，
> 用 Sidecar（代理容器）统一接管，业务只写业务。代表是 Istio。

- Sidecar：每个 Pod 旁挂一个 Envoy 代理，"你只管业务，网络规则交给它"
- 灰度发布：Istio 控制流量按比例（如 1% → 10% → 100%）切到新版本，用户无感

```yml
# Istio 核心两件套一句话版本
# VirtualService    ：面向用户——流量该怎么走（域名/路径/比例）
# DestinationRule   ：面向流量——目标 Pod 的子集和熔断重试策略
```

如果不需要微服务灰度/熔断治理，跳过 ISTIO 不影响日常部署。

---

# reference

- **速成参考（中文，先看这份）**：https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/9EX8Cp45
- kubectl 速查：https://kubernetes.io/docs/reference/kubectl/quick-reference/
- K8s 官方概念：https://kubernetes.io/zh-cn/docs/concepts/
- Helm 入门：https://helm.sh/zh/docs/intro/quickstart/