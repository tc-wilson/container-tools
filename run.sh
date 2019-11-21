#!/bin/bash

function sigfunc() {
	exit 0
}
trap sigfunc TERM INT SIGUSR1

git clone https://github.com/jianzzha/container-tools.git /root/container-tools
cd /root/container-tools

echo check env
echo "tool=$tool, DURATION=$DURATION, trace=$trace"
sleep infinity

if [ -d $tool ]; then
    cd $tool
    sleep infinity
else
    echo "sepcified tool directory $tool not exists"
    sleep infinity 
fi

