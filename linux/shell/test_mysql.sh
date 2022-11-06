#!/bin/bash

echo "-------method one--------"

if [ $(netstat -tunpl | grep mysql | wc -l) -eq "1" ]
    then 
        echo "mysql is running"
else
    echo "mysql is stopped"
    systemctl start mariadb
fi

echo "-------method two--------"

if [ $(ss -tunpl | grep mysql | wc -l) -eq "1" ]
    then 
        echo "mysql is running"
else
    echo "mysql is stopped"
    systemctl start mariadb
fi

echo "-------method three--------"

if [ $(lsof -i tcp:3306 | wc -l) -gt "0" ]
    then 
        echo "mysql is running"
else
    echo "mysql is stopped"
    systemctl start mariadb
fi

echo "-------method four--------"

php /shell/mysql_test.php

if [ "$?" -eq "0" ]
    then 
        echo "mysql is running"
else
    echo "mysql is stopped"
    systemctl start mariadb
fi

echo "-------method five--------"

python3 /shell/mysql_test.py

if [ "$?" -eq "0" ]
    then 
        echo "mysql is running"
else
    echo "mysql is stopped"
    systemctl start mariadb
fi