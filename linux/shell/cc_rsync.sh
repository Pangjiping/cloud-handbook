#!/bin/bash

# author: epha
# -ne if 条件的不等于，$#返回传递给脚本的参数个数，$0获取脚本文件名

if [ "$#" -ne "1" ]
    then
        echo "Usage: $0 {start|stop|restart}"
        exit 1
fi

# 当用户选择start rsync
if [ "$1" = "start" ]
    then 
        /usr/bin/rsync --daemon
        sleep 2
        # 验证端口是否启动
        if [ $(netstat -tunlp | grep rsync | wc -l) -ge "1" ]
            then
                echo "Rsync started"
                exit 0
        fi

# 当用户选择stop
elif [ "$1" = "stop" ]
    then
        killall rsync & > /dev/null
        sleep 2
        if [ $(netstat -tunlp | grep rsync | wc -l) -eq "0" ]
            then
                echo "Rsync stopped"
                exit 0
        fi

# 当用户选择restart
elif [ "$1" = "restart" ]
    then
        killall rsync & > /dev/null
        sleep 1
        killpro=$(netstat -tunlp | grep rsync | wc -l)
        /usr/bin/rsync --daemon
        sleep 1
        startpro=$(netstat -tunlp | grep rsync | wc -l)
        if [ "$killpro" -eq "0" -a "$startpro" -ge "1" ]
            then
                echo "Rsync restarted"
                exit 0
        fi
else
    echo "Usage: $0 {start|stop|restart}"
    exit 1
fi