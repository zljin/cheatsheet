## git

https://learngitbranching.js.org/?locale=zh_CN

https://education.github.com/git-cheat-sheet-education.pdf

> Git是一个分布式版本控制工具,Github是通过Git进行版本控制的软件源代码托管服务平台
![image](https://cdn.jsdelivr.net/gh/zljin/img_bed/gitflow.png?raw=true)


## git Strategy

we have master,uat,sit branch

1. checkout feature/hotfix branch from master
2. merge feature/hotfix to sit branch if test pass
3. merge feature/hotfix to uat branch if test pass
4. checkout release/r20260804 branch from master and then feature/hotfix merge to it
5. release release/r20260804 branch if prod heatch check success, and finally merge back to master


## 如何将本地电脑与github建立ssh

1、输入命令后在/home/.ssh目录下生成id_rsa(私钥)和id_rsa.pub(公钥)

```sh
ssh-keygen-C "your_email@example.com"
```

2、将公钥添加到github账户中即可

```
copy C:\Users\lenovo\.ssh\id_rsa.pub to github --> setting --> ssh config item
```

3、测试连接

```sh
ssh-T git@github.com
```

## git push太慢怎么办？

> 能科学上网直接走代理即可

```sh
方法一：设置VPN代理
git config —global -l
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy https://127.0.0.1:7897
```


