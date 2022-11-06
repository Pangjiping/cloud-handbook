#!/bin/bash

free_mem=$(free -m | awk 'NR==2' {print "$NF"})
chars="current memory is ${free_mem}"

if [ "$free_mem" -lt "100" ]
    then
        echo "$chars" | tee /tmp/messages.txt
        mail -s "$(date +%F-%T)$chars" 13626376642@163.com < /tmp/messages.txt
fi