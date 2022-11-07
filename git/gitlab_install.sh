#!/bin/bash

# author: epha
# usage: gitlab install
# data: 2022.11.7
# platform: cntos7

# 机器内存检查，小于4GB不允许安装[todo]

# install dependence
echo "start install dependence ..."

sudo yum install -y curl policycoreutils-python openssh-server perl

sudo systemctl enable sshd
sudo systemctl start sshd

# config image
curl -fsSL https://packages.gitlab.cn/repository/raw/scripts/setup.sh | /bin/bash

# start install
# change ip address [todo]
sudo EXTERNAL_URL="http://192.168.44.103" yum install -y gitlab-jh

# start server
gitlab-ctl start
