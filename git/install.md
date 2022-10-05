# **Git简介**

## **Git、Github、Gitlab区别**

Git是一个开源的分布式版本控制系统，用于敏捷高效地处理任何项目。Git是Linus Torvalds为了帮助管理Linux内核开发而开发的一个开源的版本控制软件。

Github是在线的基于Git的代码托管服务。Github是2008年由Ruby on Rails编写而成，Github同时提供付费账户和免费账户。这两种账户都可以创建公开的代码仓库，只有付费账户可以创建私有的代码仓库（免费账户创建的私有仓库不允许协作）。Gitlab解决了这个问题，可以在上面创建免费的私人repo

![img](https://www.ajfriesen.com/content/images/2022/04/gitconfig.png)

<br>

## **Git和SVN的区别**

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

## **Git客户端**

### **Git安装**

```bash
$ yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
$ yum -y install git git-all git-core
$ git --version
```

### **Git配置**

Git提供了一个叫做git config的工具，专门用来配置或者读取相应的工作环境变量。

这些环境变量，决定了Git在各个环节的具体的工作方式和行为。这些变量可以存放在以下三个不同的地方：
* `/etc/gitconfig`文件: 系统中对所有用户都普遍适用的配置。若使用`git config`时使用`--system`选项，读写的就是这个文件。
* `~/.gitconfig`文件: 用户目录下的配置文件只适用于该用户。若使用`git config`时使用`--global`选项，读写的就是这个文件。
* 当前项目的Git目录中的配置文件，也就是工作目录中的`.git/config`文件: 这里的配置仅仅针对当前项目有效，每一个级别的配置都会覆盖上层的相同配置，所以`.git/config`里面的配置会覆盖掉`/etc/gitconfig`中的同名变量。

#### **用户信息**

配置个人的用户名和电子邮件地址:

```bash
$ git config --global user.name "test"
$ git config --global user.email "test@example.com"
```

如果使用了`--global`选项，那么更改的配置文件就是位于用户主目录下面的那个，以后所有的项目都会默认使用这里配置的用户信息。

如果要在某个特定的项目中使用其他名字或者邮箱，只需要去掉`--global`选项重新配置即可，新的设定保存在当前项目的`.git/config`文件中。

#### **文本编辑工具**

Git默认使用vi或者vim编辑器，一般而言不会修改这个配置。如果你有其他的偏好，比如使用Emacs，可以重新配置

```bash
$ git config --global core.editor emacs
```

#### **差异分析工具**

还有一个比较常用的是，在解决合并冲突时使用哪种差异分析工具，比如要改用vimdiff的话：

```bash
$ git config --global merge.tool vimdiff
```

Git可以理解kdiff3、meld、xxdiff、emerge、vimdiff、gvimdiff、ecmerge和opendiff等合并工具分的输出信息

#### **查看配置信息**

要检查已有的配置信息，可以使用`git config --list`命令

```bash
$ git config --list
http.postbuffer=2M
user.name=test
user.email=test@example.com
```

有时候会看到重复的变量名，那就说明它们来自不同的配置文件，不过git实际采用的是最后一个。这些配置我们可以在`/etc/gitconfig`和`~/.gitconfig`文件中看到。