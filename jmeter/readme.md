文档参考：
https://blog.csdn.net/m0_47747596/article/details/131658904

下载
https://jmeter.apache.org/download_jmeter.cgi

安装插件
https://jmeter-plugins.org/downloads/old/

JMeterPlugins-Standard-1.4.0.jar
jpgc-autostop-0.1.jar
you need to add them to your jmeter/lib/ext directory

测试类型：

peak test: provide high tps test about 1 hour
capacity test: provide increasing tps test about 1 hour.aim to check the baseline to peak test or soak test
soak test: provide medium tps test about 8 hour. check system if stable
peak test: 1 hour high volume test


如何设置过期token:
you could use JSON Extractor,JSR223 PostProcessor,BeanShell Sampler to refresh token

Debug Sampler get env properties

```groovy
props.put("tokenValue","123")

${__setProperty(token,${tokenValue},)}

${__P(token,)}
```



