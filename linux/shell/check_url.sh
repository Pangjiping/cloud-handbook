#!/bin/bash

usage(){
    echo "Usage: $0 url"
    exit 1
}

check_url(){
    wget --spider -q -o /dev/null --tries=1 -T 5 "$1"

    if [ "$?" -eq 0 ]
        then
            echo "$1 is running..."
    else
        echo "$1 is down..."
    fi
}

# 设置一个入口函数
main(){
    if [ "$#" -ne "1" ]
        then
        usage
    fi
    
    check_url "$1"
}

main "$*"



