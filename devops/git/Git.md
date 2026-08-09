# Git

> Git 是分布式版本控制工具；GitHub 是基于 Git 的代码托管平台。
> 快速练习（可视化游戏）：https://learngitbranching.js.org/

![gitflow](https://cdn.jsdelivr.net/gh/zljin/img_bed/gitflow.png?raw=true)

## 一、装完先配身份（否则 commit 报错）

```sh
git config --global user.name "name"
git config --global user.email "you@example.com"
git config --global -l          # 查看配置
```

## 二、本地基础流程（每天必用）

```sh
git init              # 新项目初始化
git status            # 看有哪些改动
git add .             # 暂存改动
git commit -m "提交说明"   # 提交到本地仓库
git commit --amend -m "新说明"   # 覆盖上一次提交（改说明/补漏提交，未推送时用）
git log --oneline     # 看提交历史
git diff              # 看未暂存的改动内容
```

**先加 .gitignore（Java 项目）**

```sh
printf "target/\n.idea/\n*.log\n" >> .gitignore
git rm -r --cached target/     # 已误提交的文件，解除跟踪但保留本地文件
git add . && git commit -m "remove target"    # 提交忽略生效
```

## 三、远程仓库（GitHub / GitLab / 内网）

```sh
git remote add origin <url>        # 关联远程
git remote set-url origin <url>    # 改远程地址
git remote -v                      # 看远程地址
git clone <url>                    # 克隆项目
git pull                           # 拉取远程最新（= fetch + merge）
git pull --rebase                  # 拉取后把我的提交"排在远程最新之后"，历史更线性（团队常用）
git push -u origin master          # 首次推送并绑定上游（-f 强制覆盖，慎用）
git push origin --delete <branch>  # 删除远程分支
```

**push 太慢（科学上网）：**
```sh
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy https://127.0.0.1:7897
```

## 四、分支操作

```sh
git branch                        # 查看分支
git checkout -b feature/xxx       # 新建并切换（推荐）
git checkout master               # 切换分支
git merge <branch>                # 把 branch 合并进当前分支
git rebase <branch>               # 变基：重放提交，历史更线性（慎用，别动已推送的）
```

**合并冲突（多人改同一个文件必遇到）：**

```sh
# 冲突时 `git status` 会标出冲突文件，文件里会有：
#   <<<<<<< HEAD     ← 当前分支的内容
#   =======
#   >>>>>>> branch   ← 要合并进来的分支的内容
# 手动改成最终内容后：
git add .
git commit -m "解决冲突"
# 想放弃这次合并：
git merge --abort
```

## 五、撤销 / 回滚（最容易搞混，先记这张表）

| 场景 | 命令 |
|---|---|
| 放弃工作区改动（还没 add） | `git checkout -- <file>` |
| 撤销本地已 commit 的提交（未推送） | `git reset --hard <commitId>` |
| 撤销已 push 的提交 | `git revert <commitId>`（生成反向提交，不删历史） |
| 改错了想找回 | `git reflog` → `git reset --hard <id>` |

```sh
git reset --hard HEAD~1     # 本地回退到上一个提交
git revert --no-commit <id> # 先反做、不自动提交，确认后再 commit
git reflog                  # 所有操作记录，找"已删"的提交
git diff origin/master      # 本地和远程的差异
```

## 六、搬运 / 合并提交

```sh
git cherry-pick <commitId>       # 把别的分支的某个提交搬到当前分支
git cherry-pick --no-commit id1 id2 id3 && git commit -m "合并成一个提交"
git rebase -i HEAD~4             # 交互式合并最近4个提交，把要合并的改为 s(squash)
```

## 七、Stash（活干一半，先切分支）

```sh
git stash save "说明"    # 暂存当前改动，工作区变干净
git stash list           # 看暂存列表
git stash pop            # 恢复最近一次暂存
```

## 八、团队分支策略（master / sit / uat / release）

```
feature/hotfix(开发) --测试--> sit(联调) --测试--> uat(预发) --生产--> release(发版)
```

1. 从 `master` 拉 `feature/hotfix` 分支开发
2. 开发+自测通过 → 合并到 `sit`
3. 联调通过 → 合并到 `uat`
4. 发布前从 `master` 拉 `release/日期`，把 feature/hotfix 合入它
5. 生产健康检查通过 → 合并回 `master`

## 九、本地与 GitHub 建立 SSH（免密推送）

```sh
ssh-keygen -C "you@example.com"   # 生成 id_rsa(私钥) + id_rsa.pub(公钥)
```
把 `~/.ssh/id_rsa.pub` 内容贴到 GitHub → Settings → SSH keys，然后：

```sh
ssh -T git@github.com             # 测试连接
```

---

> 清空所有历史重新提交（慎用）：`rm -rf .git && git init && git add . && git commit -m "Initial commit"`