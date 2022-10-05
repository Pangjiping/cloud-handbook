# **Git常用的指令**

## **本地没有代码库，从新开始**

```bash
$ git clone git@xxx.git
$ cd xxx                    # clone之后进入项目工作区
$ touch README.md           # 新建readme文件
$ git add README.md         # 添加README.md到暂存区
$ git commit -m "init commit"
$ git push -u origin master # 推送到远端仓库master分支
```

<br>

## **使用本地代码库直接构建远端仓库**

```bash
$ cd xxx                            # 进入项目目录
$ git bash git init                 # 初始化git仓库
$ git remote add origin git@xxx.git # 添加远程项目地址
$ git add .
$ git commit -m "rebuild remote repo"
$ git push -u origin master
```

* `git clone`时，git不会对比本地和服务器的文件，也就不会有冲突
* 建议确定完全覆盖本地的时候用clone，不确定会不会有冲突时用`git pull`，将远端仓库代码down下来

<br>

## **常用命令**

```bash
$ git init                  # 初始化git仓库，用的不多
$ git add main.go           # 添加某个文件到暂存区
$ git add .                 # 添加所有文件到暂存区
$ git commit -m "xxx"       # 提交更改
$ git log                   # 查看所有版本日志
$ git log --oneline         # 查看版本日志，更易读
$ git status                # 查看暂存区的状况
$ git diff                  # 查看现在文件与上一个commit的区别
$ git reset --hard HEAD^    # 回退到上一个commit
$ git reset --hard xxx      # 回退到xxx版本，xxx可以通过git log --oneline来看
$ git pull origin master    # 从master分支pull到本地
$ git push -u origin master # push到远端master分支
$ git pull                  # 默认从master分支pull
$ git push                  # 默认push到master分支
```

<br>

## **版本回退**

```bash
$ git reset --hard HEAD^     # 回退到上一个commit
$ git reflog                 # 查看历史版本信息
$ git reset --hard commit_id # 回退到指定commit_id
```

<br>

## **分支管理**

```bash
$ git checkout -b dev # 创建dev分支，并切换到该分支
$ git branch          # 查看当前分支
$ git checkout master # 切换回master分支
$ git merge dev       # 把dev分支合并到master上
$ git merge           # 用于合并指定分支到当前分支
$ git branch -d dev   # 删除dev分支
```

<br>

## **冲突解决**

一般而言，冲突解决的思路就是找出冲突内容，优先保留所有的冲突被容，之后再根据具体的代码逻辑来把过时的逻辑删除掉。如果是大型项目管理的话，建议在和其他分支遇到冲突时，找到冲突分支的commiter，让他来做冲突解决。

```bash
$ git status # 查看冲突内容
```

<br>
