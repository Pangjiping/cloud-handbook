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

main_url=$(sed -n '/class="last".*末页.*/p' $temp_file | egrep -o 'http:.*p[0-9]{1,}')

pages=$(echo $main_url | sed -n 's#^.*p##gp')

if [ "$pages" -gt 0 ] &>/dev/null
then
  echo "please wait..."
else
  echo "you input url is not homepage"
  rm -f $temp_file
  rm -f $blog_file
  exit 1
fi

ur=$(echo $main_url | sed -rn 's#[0-9]{1,}$##gp')

for ((i=1;i<=$pages;i++))
do
  wget -q -O $temp_file ${ur}$i &>/dev/null
  egrep -A 1 '<a class="tit" | class="time' $temp_file | sed '/^\-\-/d' | sed -r 's#[ ]+# #g'   >> $blog_file
  sleep 0.5
done

# clear temp file
>$temp_file

# ===============================================================
action "The blogger’s blog information has been downloaded locally" /bin/true
echo "Extracting required data from downloaded data ......"
echo "please wait ....."
# ===============================================================

i=0
while read line
do
  ((++i))
  case "$i" in
  1)
    # get blog posting time
    time=$(echo $line | sed -r 's#^.*>发布于：(.*)</a>#\1#g')
    ;;
  3)
    href=$(echo $line | sed -r 's#^.*href=\"(.*)\">#\1#g')
    ;;
  4)
    title=$(echo $line | sed -r 's#^(.*)<.*$#\1#g')
    ;;
  *)
  esac

  if [ "$i" -eq 4 ]
  then
    i=0
    echo "<a href=\"$Href\">$Time---$Title</a><br/>" >> $temp_file
  fi
done < $blog_file

# clear file
>&blog_file

cat $temp_file | sort -rt '>' -k2 >> $blog_file
rm -f $temp_file

action "success" /bin/true