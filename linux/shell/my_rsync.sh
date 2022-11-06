#!/bin/bash

lsb_functions="/lib/lsb/init-functions"
if test -f $lsb_functions ; then
    . $lsb_functions
else
    init_functions="/etc/init.d/functions"
    if test -f $init_functions; then
        . $init_functions
    fi

    log_success_msg()
    {
        echo " SUCCESS! $@"
    }
    log_failure_msg()
    {
        echo " ERROR! $@"
    }
fi

function usage()
{
    echo "Usage: $0 {start|stop|restart}"
    exit 1
}

function start()
{
    /usr/bin/rsync --daemon
    sleep 1
    if [ $(netstat -tunlp | grep rsync | wc -l) -ge "1" ]
        then
            log_success_msg "rsync is started"
    else
        log_failure_msg "rsync isn't started"
    fi
}

function stop()
{
    killall rsync & > /dev/null
    sleep 1
    if [ $(netstat -tunlp | grep rsync | wc -l) -eq "0" ]
        then
            log_success_msg "rsync is stopped"
    else
        log_failure_msg "rsync isn't stopped"
    fi
}

function restart()
{
    killall rsync & > /dev/null
    sleep 1
    killpro=$(netstat -tunlp | grep rsync | wc -l)
    /usr/bin/rsync --daemon
    sleep 1
    startpro=$(netstat -tunlp | grep rsync | wc -l)
    if [ "$killpro" -eq "0" -a "$startpro" -ge "1" ]
        then
            echo "Rsync restarted"
            exit 0
    fi
}

function main()
{
    if [ "$#" -ne "1" ]
        then
            usage
    fi

    if [ "$1" = "start" ]
        then start
    elif [ "$1" = "stop" ]
        then stop
    elif [ "$1" = "restart" ]
        then restart
    else
        usage
    fi
}

main "$*"