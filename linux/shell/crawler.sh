#!/bin/bash

source /etc/profile
. /etc/init.d/functions

# create a temporary file
temp_file="/tmp/.$(date +%Y%m%d_%H%M%S).log.tmp"
touch $temp_file

# store web page information
blog_file="/tmp/(date +%Y%m%d_%H%M%S)_blog.html"
touch $blog_file

# let the user enter the 51cto blogger's homepage URL
read -p 'please input website' website
wget -q -O $temp_file $website & > /dev/null
[ $? -ne 0 ] && echo "you input website is not exist" && exit 1

