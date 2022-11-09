#!/bin/bash

# author: epha
# shell练习

# 循环ping102.168.110网段的所有主机
function my_ping()
{
    i=1
    for i in {1..254}
    do
        ping -c 2 -w 3 -i 0.3 102.168.110."$i" & > /dev/null
        if [ $? -eq 0 ]
        then
            echo "192.168.110.$i is yes"
        else
            echo "192.168.110.$i is no"
        fi
        ((i++))
    done
}

# for 批量创建用户
function create_user()
{
    user=$`cat /opt/user.txt`
    for i in $user
    do
      useradd $i
      echo "1234" | passwd --stdin $i
    done
}

# 创建存放1-100奇数的数组里
function my_odd()
{
    for ((i=0;i<=100;i++))
    do
      if [ $[$i%2] -eq "1" ]
      then
        arr[$[$i-1]/2]=$i
      fi
    done
    echo ${arr[*]}
}

# 创建任意数字及长度的数组，根据客户的需求加入元素
function my_func1()
{
    i=0
    while true
    do
      read -p "是否输入元素 (yes/no):" doing
      if [ $doing == "no" ]
      then
        break
      fi

      read -p "请存入第$[$i+1]个元素:" key
      shuzu[$i]=$key
      ((i++))
    done
    echo ${shuzu[*]}
}

# 将一个数组中的所有不够60的提到60
function my_func2()
{
    num=(90 90 90 90 90 90 90 90 90 20 20)
    for ((i=0;i<=10;i++))
    do
      if [ $((num[$i])) -lt 60 ]
      then
        num[$i]=60
      fi
    done
    echo ${num[*]}
}

# 判断数组中最大的数
function find_max()
{
  score=(72 63 90 45 75)
  temp=0
  for ((i=0;i<${#score[*]};i++))
  do
    if [ ${score[$i]} -gt $temp ]
    then
      temp=${score[$i]}
    fi
  done
  echo ${temp}
}

# 检测本机当前用户是否为超级管理员，如果是管理员，则使用yum安装xxx
# 如果不是管理员，提示你不是管理员
function install_xxx() {
    if [ $USER == "root" ]
    then
      #yum -y install vsftpd
      echo "xxx installed"
    else
      echo "您不是管理员，无权限操作"
    fi
}

# 自动调整网络配置
function adjuest_network() {
    ip="www.baidu.com"
    ping -c 2 $ip & > /dev/null
    if [ $? -eq 0 ]
    then
      echo "百度没问题"
      exit 0
    else
      echo "请主人稍等，我正在更改您的网卡"

      sed -ri '/^IPADDR=/cIPADDR=192.168.110.132' /etc/sysconfig/network-scripts/ifcfg-ens33
      sed -ri '/^GATEWAY=/cGATEWAY=192.168.110.2' /etc/sysconfig/network-scripts/ifcfg-ens33
      sed -ri '/^DNS1=/cDNS1=8.8.8.8' /etc/sysconfig/network-scripts/ifcfg-ens33
      echo "网卡配置文件已改完  正在重启网络服务"
      systemctl restart network
    fi

    ping -c 2 $ip & > /dev/null
    if [ $? -eq 0 ]
    then
      echo "准备就绪"
      exit 0
    else
      echo "请检查你绑定的网卡是不是vm8"
      exit 1
    fi
}

# 为指定用户发送在线消息
function message() {
    username=$1
    if [ $# -lt 1 ]
    then
      echo "Usage: `basename $0` <username> [<message>]"
      exit 1
    fi

    # 判断账号是否存在
    if grep "^$username:" /etc/passwd &> /dev/null; then :
    else
      echo "用户不存在"
      exit 2
    fi

    # 判断用户是否在线
    until who | grep "$username" &> /dev/null
    do
      echo "用户不在线，尝试连接"
      sleep 3
    done

    mes=$*
    echo "$mes" | write "$username"
}

adjuest_network


