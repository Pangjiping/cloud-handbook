# **gitlab服务的部署**

centos8

* 关闭防火墙、SELinux，开启邮件服务
```bash
$ systemctl disable firewalld
$ chkconfig iptables off
$ systemctl start postfix
$ systemctl enable postfix
```

* 安装gitlab依赖包

```bash
$ yum install -y curl openssh-server openssh-clients postfix cronie python3-policycoreutils
```

* 添加官方的yum源

```bash
$ curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
```

因为官方源太慢，可以用清华yum源
```bash
$ vim /etc/yum.repos.d/gitlab-ce.repo
[gitlab-ce]
name=Gitlab CE Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el$releasever/
gpgcheck=0
enabled=1
```

* 安装gitlab
```bash
$ yum -y install gitlab-ce # 安装最新版
$ yum -y install gitlab-ce-x.x.x # 安装指定版本
```

* 查看gitlab版本
```bash
$ head -l /opt/gitlab/version-manifest.txt
```

* gitlab配置登录链接
```bash
$ vim /etc/gitlab/gitlab.rb
***
## GitLab URL
##! URL on which GitLab will be reachable.
##! For more details on configuring external_url see:
##! https://docs.gitlab.com/omnibux/settings/configuration.html#configuring-the-external-url-for-gitlab

# 没有域名，可以使用本机ip地址
external_url 'http://192.168.1.172'
$ grep "^external_url" /etc/gitlab/gitlab.rb
```

* 初始化gitlab

```bash
$ gitlab-ctl reconfigure
```

* 启动gitlab服务

```bash
$ gitlab-ctl start
$ lsof -i:80 # 查看80端口是否开启服务
```

<br>

## **Gitlab的使用**

在浏览器中输入http://192.168.1.172，然后change password，并使用root用户登录即可

gitlab命令行修改密码

```bash
$ gitlab-rails console production
irb(main):001:0>user = User.where(id: 1).first # id为1的是超级管理员
irb(main):002:0>user.password = 'yourpassword' # 密码至少为8个字符
irb(main):003:0>user.save!                     # 如果没有问题，返回true
exit                                           # 退出
```

gitlab服务管理

```bash
$ gitlab-ctl start          # 启动所有gitlab组件
$ gitlab-ctl stop           # 停止所有gitlab组件
$ gitlab-ctl restart        # 重启所有gitlab组件
$ gitlab-ctl status         # 查看服务状态
$ gitlab-ctl reconfigure    # 初始化服务
$ vim /etc/gitlab/gitlab.rb # 修改默认配置文件
$ gitlab-ctl tail           # 查看日志
```

