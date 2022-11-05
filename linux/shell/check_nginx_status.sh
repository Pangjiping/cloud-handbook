#!/bin/bash

checkUrl(){
    timeout=5
    fails=0
    success=0

    while true
        do
            wget --timeout=${timeout} --tries=1 http://pythonav.cn/ -q -O /dev/null
            if [ $? -ne 0 ]
                then
                    let fails=fails+1
            else
                    let success+=1
            fi

            # 当成功次数>=1，表明网站正常
            if [ ${success} -ge 1 ]
                then
                    echo "恭喜你，该网站在正常运行"
                    exit 0
            fi

            # 当错误次数>=2，报警
            if [ ${fails} -ge 2 ]
                then
                    echo "该网站有问题"
                    exit 2
            fi
        done
}

checkUrl