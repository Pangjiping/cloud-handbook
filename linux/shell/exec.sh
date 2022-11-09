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


function create_user()
{
    user=$`cat /opt/user.txt`
    for i in $user
    do
      useradd $i
      echo "1234" | passwd --stdin $i
    done
}


