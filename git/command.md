
```sh
git help [command]

git config --global -l
git config --global user.name ""

git init
git add .
git commit -m ''
git remote add origin https://github.com/zljin/demo_boot.git
git remote set-url origin https://github.com/zljin/demo_boot.git
git remote -v
git push -u origin master -f
git clone https://github.com/zljin/demo_boot.git
git pull

## Branch & Merge

git checkout -b newbranch
git branch
git merge <your_branch>
git rebase <your_branch>

# move HEAD
git branch -f <your_branch> HEAD~3
git checkout <your_branch>^
git rebase -i HEAD~4

## Combile multiple commit

git cherry-pick [commitId of another branch]
git cherry-pick --no-commit commit-id-1
git cherry-pick --no-commit commit-id-2
git cherry-pick --no-commit commit-id-3

git commit -m 'change title'

git log

## Revert commit

git revert [target commit-id]

or

git revert --no-commit [commit-id]
git commit -m 'chage title'

## Delete local repo commit

git reset --hard [target commitId]


## Stash
git stash save "willbacktag"
git stash list
git stash pop

# 清除所有提交记录，重新提交
rm -rf .git
git init
git add .
git commit -m "Initial commit"

# 回滚本地的修改
git reset --hard HEAD~1
git reflog
git reset --hard abc123
git diff origin/master
```



