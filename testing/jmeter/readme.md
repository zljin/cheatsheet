# JMeter

- 文档参考：https://blog.csdn.net/m0_47747596/article/details/131658904
- 下载：https://jmeter.apache.org/download_jmeter.cgi
- 插件：https://jmeter-plugins.org/downloads/old/（如 `JMeterPlugins-Standard-1.4.0.jar`、`jpgc-autostop-0.1.jar`，放入 `jmeter/lib/ext` 目录）

## 测试类型

| 类型 | 时长 | 目标 |
|---|---|---|
| **Peak** | 1 小时持续高 TPS | 扛压上限 |
| **Capacity** | 1 小时递增 TPS | 摸到基线，导向 peak / soak |
| **Soak** | 8 小时中等 TPS | 验证长期稳定，查内存泄漏 |

## 过期 Token 刷新

> 用 JSON Extractor + JSR223 PostProcessor / BeanShell Sampler 拿新 token，`__setProperty` 存为全局属性供后续请求用。

```groovy
// JSR223 PostProcessor 中：token 提取后存为全局属性
props.put("tokenValue", "123")
${__setProperty(token, ${tokenValue},)}

// 后续请求中读取
${__P(token,)}
```

Debug Sampler 可以查看 current env / 全局属性值。