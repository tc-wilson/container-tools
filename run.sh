#!/bin/bash

function sigfunc() {
	exit 0
}
trap sigfunc TERM INT SIGUSR1

echo "######################################"
env
echo "######################################"

git clone https://github.com/jianzzha/container-tools.git /root/container-tools
cd /root/container-tools

if [ -d /root/container-tools/$tool ]; then
    echo "found tool directory $tool"
else
    echo "env 'tool' not specified or tool directory $tool not exists!"
    echo "availble tool directory:"
    echo "$(ls /root/container-tools)"
    sleep infinity 
fi

if [ -f /root/container-tools/$tool/cmd.sh ]; then
    echo "found $tool/cmd.sh, executing"
else
    echo "tool/cmd.sh not exists, can't continue"
    sleep infinity
fi

exec /root/dumb-init -- /root/container-tools/$tool/cmd.sh
