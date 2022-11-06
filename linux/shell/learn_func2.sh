#!/bin/bash

# 函数定义和调用不在同一个文件中
# 该文件调用 learn_func.sh中定义的函数 my_func


# 利用.或者source命令读取带func定义的脚本，将其变量加载到当前的shell环境中

[ -f ./learn_func.sh ] && source ./learn_func.sh || exit

#my_func
hello123 "$1" "$2" "$3"