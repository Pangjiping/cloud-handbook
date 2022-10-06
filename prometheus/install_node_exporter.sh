#!/bin/bash
#
#********************************************************************
#Date:              2022-05-20
#FileName:          install_node_exporter.sh
#Description:       The test script
#Copyright (C):     2022 All rights reserved
#********************************************************************
 
NODE_EXPORTER_VERSION=1.3.1
NODE_EXPORTER_FILE="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR=/usr/local
 
HOST=`hostname -I|awk '{print $1}'`
 
 
. /etc/os-release
 
msg_error() {
  echo -e "\033[1;31m$1\033[0m"
}
 
msg_info() {
  echo -e "\033[1;32m$1\033[0m"
}
 
msg_warn() {
  echo -e "\033[1;33m$1\033[0m"
}
 
 
color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}
 
 
install_node_exporter () {
    if [ ! -f  ${NODE_EXPORTER_FILE} ] ;then
        wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_FILE} || \
            { color "下载失败!" 1 ; exit ; }
    fi
    [ -d $INSTALL_DIR ] || mkdir -p $INSTALL_DIR
    tar xf ${NODE_EXPORTER_FILE} -C $INSTALL_DIR
    cd $INSTALL_DIR &&  ln -s node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64 node_exporter
    mkdir -p $INSTALL_DIR/node_exporter/bin
    cd $INSTALL_DIR/node_exporter &&  mv node_exporter bin/ 
      
    cat >  /etc/profile.d/node_exporter.sh <<EOF
export NODE_EXPORTER_HOME=${INSTALL_DIR}/node_exporter
export PATH=\${NODE_EXPORTER_HOME}/bin:\$PATH
EOF
 
}
 
 
node_exporter_service () {
    cat > /lib/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target
 
[Service]
Type=simple
ExecStart=$INSTALL_DIR/node_exporter/bin/node_exporter
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now node_exporter.service
}
 
 
start_node_exporter() { 
    systemctl is-active node_exporter.service
    if [ $?  -eq 0 ];then  
        echo 
        color "node_exporter 安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        msg_info "http://$HOST:9100/metrics" 
    else
        color "node_exporter 安装失败!" 1
        exit
    fi 
}
 
install_node_exporter
 
node_exporter_service
 
start_node_exporter