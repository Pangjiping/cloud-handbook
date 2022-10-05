# **Git简介**

## **Git、Github、Gitlab区别**
---

Git是一个开源的分布式版本控制系统，用于敏捷高效地处理任何项目。Git是Linus Torvalds为了帮助管理Linux内核开发而开发的一个开源的版本控制软件。

Github是在线的基于Git的代码托管服务。Github是2008年由Ruby on Rails编写而成，Github同时提供付费账户和免费账户。这两种账户都可以创建公开的代码仓库，只有付费账户可以创建私有的代码仓库（免费账户创建的私有仓库不允许协作）。Gitlab解决了这个问题，可以在上面创建免费的私人repo


![img](https://www.ajfriesen.com/content/images/2022/04/gitconfig.png)

<br>

## **Git和SVN的区别**
---

Git不仅仅是一个版本控制系统，它也是一个内容管理系统，工作管理系统等。

**Git和SVN区别**
* Git是分布式的，SVN不是。这是Git区别于其他版本管理系统的核心
* Git把内容按照元数据方式存储，而SVN是按文件。
* Git分支和SVN分支不同。分支在SVN中就是版本库中的另外的一个目录。
* Git没有一个全局的版本号，而SVN有。这是目前为止Git缺少的最大特征
* Git内容完整性要优于SVN。Git的内容存储使用的是SHA-1哈希算法，这能确保代码的完整性，确保在磁盘需要故障和网络问题时降低对版本库的破坏。

本文不关注SVN，有需要可以自行学习

<br>

## **部署Git服务**
---

准备两个服务器：git-server和git-client。虽然git没有客户端和服务器的概念，但是一般来讲都需要有一个线上的git仓库来保存项目代码，可以把这台机器看作git-server。

安装git服务

```bash
$ yum install git git-core gitweb -y
```

设置git专用的用户名、密码和workspace [git-server]

```
$ useradd git
$ passwd git
$ mkdir /git-root/
$ cd /git-root/
$ git init --bare shell.git # 初始化shell代码库
```

**git init和git init --bare**
* 使用`--bare`选项时，不再生成`.git`目录，而是只生成`.git`目录下面的版本历史里路文件，这些版本历史记录文件也不再存放在`.git`目录下，而是直接存放在版本库的根目录下。
* 使用`git init`初始化的版本库用户可以在该目录下执行所有git方面的操作。但是别的用户在将更新`push`
上来的时候容易出现冲突。
* 使用`git init --bare`的方式创建一个所谓的裸仓库，之所以叫裸仓库是因为这个仓库只保存git历史提交的版本信息，而不允许用户在上面进行各种git操作，如果硬要操作的话，只会得到下面的错误信息 - `This operation must be run in a work tree`。这个就是最好把远端仓库初始化为bare仓库的原因。

更改远端仓库所有者权限 [git-server]

```bash
$ chown -R git:git shell.git
```

以git账号登录 [git-server]

```bash
$ su - git
$ ssh-keygen -t rsa
$ cd .ssh/
$ cp id_rsa.pub authorized_keys
$ logout
```

测试git-server，以下操作均在git-client上执行

```bash
$ ssh-keygen
$ ssh-copy-id git@192.168.1.178 # git-server地址
$ git clone git@192.168.1.178:/git-root/shell.git
$ ls -l # 可以看到shell代码库
```

编辑代码库，测试git操作

```bash
$ cd shell/
$ vim test.sh # test for git
$ git add test.sh
$ git config --global user.email "test@example.com"
$ git config --global user.name "test"
$ git commit -m "test for git"
$ git push origin master
```

<br>

## **Git的工作流程**
---

一般的工作流程如下：
* 克隆Git资源作为工作目录
* 在克隆的资源上添加或修改文件
* 如果其他人修改了，你可以更新资源
* 在提交前查看修改
* 提交修改
* 在修改完成后，如果发现错误，可以撤回提交并再次修改并提交

![img](https://www.runoob.com/wp-content/uploads/2015/02/git-process.png)

<br>

## **Reference**
* https://www.runoob.com/git/git-workflow.html