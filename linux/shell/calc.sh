#!/bin/bash

print_usage(){
    printf "Please enter an integer!!!\n"
    exit 1
}

read -p "Please input a number:" firstnum

if [ -n "$(echo "$firstnum" | sed 's/[0-9]//g')" ]
then print_usage
fi

