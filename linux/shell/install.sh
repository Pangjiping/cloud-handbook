#!/bin/bash

# 1. 检查目标脚本是否存在

path="/Users/pangjiping/handbook/cloud-handbook/linux/shell"

# 判断目录是否存在
[ ! -d "$path" ] && {
    mkdir ${path} -p
}

cat << END
    1. [install lamp]
    2. [install lnmp]
    3. [exit]
    plz input the number you want: 

END

read number

# 根据number进行逻辑处理
expr "$number" + 1 & > /dev/null

# 判断上一条命令的结果
# 限制用户必须输入数字
[ $? -ne 0 ] && {
    echo "the number you input must be {1|2|3}"
    exit 1
}

# 1,2,3判断
[ "$number" -eq "1" ] && {
    echo "Start install lamp ..."
    echo "waitint..."
    sleep 2

    # 执行lamp脚本
    # 对文件权限做判断
    [ -x "$path/lamp.sh" ] || {
        echo "The file doesnot exist or cannot be exec."
        exit 1
    }

    $path/lamp.sh
    exit $?
}

[ "$number" -eq "2" ] && {
    echo "Start install lnmp ..."
    echo "waitint..."
    sleep 2

    # 执行lamp脚本
    # 对文件权限做判断
    [ -x "$path/lnmp.sh" ] || {
        echo "The file doesnot exist or cannot be exec."
        exit 1
    }

    $path/lnmp.sh
    exit $?
}

[ "$number" -eq "3" ] && {
    echo "bye"
    exit 3
}

# 限制用户只能输入1,2,3
[[ ! "$number" =~ [1-3] ]] && {
    echo "error input"
    exit 1
}

