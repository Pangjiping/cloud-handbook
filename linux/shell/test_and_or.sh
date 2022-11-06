#!/bin/bash

read -p "pls input a char:" var1

[ "$var1" -eq "1" ] && {
    echo "${var1}"
    exit 0
}

[ "$var1" -eq "2" ] && {
    echo "${var1}"
    exit 0
}

# 只能输入的是1或者2，否则就报错
[ "$var1" -ne "2" -a "$var1" -ne "1" ] && {
    echo "error"
    exit 1
}