# **Jenkins环境安装**

学习Jenkins至少需要三台服务器，当然一台下面安装三个虚拟机也行

* Gitlab服务，要求较高，最好是8G内存的
* Jenkins服务
* 测试环境服务器

centos7

<br>

## **dcoker部署jenkins**

推荐学习使用，实际部署不需要使用docker

```perl
pangjiping@mbp ~ % docker search jenkins
NAME                           DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
jenkins/jenkins                The leading open source automation server       3272                 
jenkins/jnlp-slave             a Jenkins agent which can connect to Jenkins…   151                  [OK]
jenkins/inbound-agent                                                          78                   
bitnami/jenkins                Bitnami Docker Image for Jenkins                55                   [OK]

# 拉取jenkins镜像
pangjiping@mbp ~ % docker pull jenkins/jenkins
Using default tag: latest
latest: Pulling from jenkins/jenkins
94a23d3cb5be: Pull complete 
ad68794f138d: Pull complete 
6c7fe1b6e0c4: Pull complete 
4b9275664932: Pull complete 
a8f2f4b59fc2: Pull complete 
f3193379e2a9: Pull complete 
3dd2416b17cb: Pull complete 
6d26bc7b2ad5: Pull complete 
f6a4d14f6f63: Pull complete 
8222baccab39: Pull complete 
b40a1ec611ca: Pull complete 
1dbfeb959dc6: Pull complete 
3eeb6f031df4: Pull complete 
7c6bc0184ff7: Pull complete 
28178fb088dd: Pull complete 
181dd786f585: Pull complete 
54902cf38ed5: Pull complete 
Digest: sha256:c3fa8e7f70d1e873ea6aa87040c557aa53e6707eb1d5ecace7f6884a87588ac8
Status: Downloaded newer image for jenkins/jenkins:latest
docker.io/jenkins/jenkins:latest

# 查看拉取到镜像
pangjiping@mbp ~ % docker images | grep jenkins
jenkins/jenkins   latest      6a912ff7c6e8   10 months ago   432MB

# 创建一个jenkins目录
pangjiping@mbp ~ % mkdir jenkins_home

# 启动jenkins容器
# 挂载目录需要用绝对目录
pangjiping@mbp ~ % docker run -d --name jenkins -p 8081:8080 -v /Users/pangjiping/jenkins_home:/var/jenkins_home 6a912ff7c6e8

# 查看jenkins是否已经拉起
pangjiping@mbp ~ % docker ps    
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                                         NAMES
6b5f9eeb8593   6a912ff7c6e8   "/sbin/tini -- /usr/…"   2 minutes ago   Up 2 minutes   8080/tcp, 50000/tcp, 0.0.0.0:8081->8081/tcp   jenkins

# 查看jenkins默认密码
pangjiping@mbp ~ % docker exec -it jenkins bash
jenkins@6b5f9eeb8593:/$ cat /var/jenkins_home/secrets/initialAdminPassword 
c6cfbdd25fa549c990c745424a051c1d

```

打开8081端口访问jenkins webUI

<br>
