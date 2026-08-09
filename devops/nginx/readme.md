# Nginx

- 概念详解：[Nginx笔记](https://www.cnblogs.com/zhangchao0515/p/10761169.html)（反向代理/负载均衡/动静分离）
- 配置文件示例见同目录 `nginx.conf`

## 反向代理配置要点

```nginx
# 上游服务（网关 / 后端集群，支持多个 server 做负载均衡）
upstream gulimall {
    server localhost:88;   # 映射到 gateway 服务
}

server {
    listen 80;
    server_name gulimall.com *.gulimall.com;

    # 动静分离：静态资源直接由 nginx 返回，不走后端
    location /static/ {
        root /usr/share/nginx/html;
    }

    # 指定后端上游 + 覆盖请求 Host
    location /payed {
        proxy_pass http://gulimall;
        proxy_set_header Host order.gulimall.com;
    }

    # 默认转发到网关
    location / {
        proxy_set_header Host $host;   # 保留原始 Host，网关才认得域名，很重要
        proxy_pass http://gulimall;
    }
}
```

- `location` 匹配规则：精确 `=` > 前缀 `^~` > 正则 `~` > 最长前缀。
- 生产注意：`worker_processes auto`、开 `gzip`、配 `proxy_set_header X-Real-IP $remote_addr`、WebSocket 需 `Upgrade`/`Connection` 头。