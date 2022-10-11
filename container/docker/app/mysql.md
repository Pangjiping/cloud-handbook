# **docker安装mysql**

```bash
$ docker pull mysql
$ docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -d mysql
```