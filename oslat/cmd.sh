#!/bin/bash

# env vars:
#	RUNTIME_SECONDS (default 10)
#	DISABLE_CPU_BALANCE (default "n", choices y/n)
#	USE_TASKSET     (default "n", choice y/n)	
#       manual  (default 'n', choice yn)

source common-libs/functions.sh

function sigfunc() {
	if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
		enable_balance
	fi
	exit 0
}

echo "############# dumping env ###########"
env
echo "#####################################"

echo "**** uid: $UID ****"
RUNTIME_SECONDS=${RUNTIME_SECONDS:-10}
THRESHOLD_NS=${THRESHOLD_NS:-200}

cpulist=`get_allowed_cpuset`
echo "allowed cpu list: ${cpulist}"

uname=`uname -nr`
echo "$uname"

# change list seperators from comma to new line and sort it 
cpulist=`convert_number_range ${cpulist} | tr , '\n' | sort -n | uniq`

declare -a cpus
cpus=(${cpulist})

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	disable_balance
fi

trap sigfunc TERM INT SIGUSR1
if ! command -v oslat >/dev/null 2>&1; then
	cd oslat
	git clone https://github.com/xzpeter/oslat.git
	cd oslat
	make 
	install -t /bin/ oslat
fi

for cmd in oslat; do
     command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but not installed.  Aborting"; exit 1; }
done

cyccore=${cpus[1]}
cindex=2
ccount=1
while (( $cindex < ${#cpus[@]} )); do
	cyccore="${cyccore},${cpus[$cindex]}"
	cindex=$(($cindex + 1))
        ccount=$(($ccount + 1))
done

prefix_cmd=""
if [ "${USE_TASKSET:-n}" == "y" ]; then
	prefix_cmd="taskset --cpu-list ${cyccore}"
fi
 
echo "cmd to run: oslat --runtime ${RUNTIME_SECONDS} --rtprio 1 --cpu-list ${cyccore}"

if [ "${manual:-n}" == "y" ]; then
sleep infinity
fi


if [ "${WAIT_FOR_USER:-n}" == "y" ]; then
	echo "sleeping, waiting for the user to kill the sleep before proceeding"
	sleep infinity
fi

oslat --runtime ${RUNTIME_SECONDS} --rtprio 1 --cpu-list ${cyccore}

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	enable_balance
fi
