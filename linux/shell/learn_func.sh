#!/bin/bash

# 定义函数
function my_func(){
    cd /tmp/ || exit
    echo "准备创建文件且写入信息"
    # echo "testtest" >> ./test.txt
    return 0
}

# 调用函数
# my_func

# 函数传参
function hello123(){
    echo "传参：$1 $2 $3"
    echo "参数个数为: $#"
}