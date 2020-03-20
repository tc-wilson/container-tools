#!/bin/bash

source common-libs/functions.sh

function sigfunc() {
	rm -rf {RESULT_DIR}/sysjitter_running
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

if [[ -z "${RESULT_DIR}" ]]; then
	RESULT_DIR="/tmp/sysjitter"
fi

# make sure the dir exists
[ -d ${RESULT_DIR} ] || mkdir -p ${RESULT_DIR} 


cpulist=`get_allowed_cpuset`
echo "allowed cpu list: ${cpulist}"

# change list seperators from comma to new line and sort it 
cpulist=`convert_number_range ${cpulist} | tr , '\n' | sort -n | uniq`

declare -a cpus
cpus=(${cpulist})

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	disable_balance
fi

trap sigfunc TERM INT SIGUSR1

if ! command -v sysjitter >/dev/null 2>&1; then
	[ -d /tmp/sysjitter ] && /usr/bin/rm -rf /tmp/sysjitter
	mkdir -p /tmp/sysjitter
	curl -L https://www.openonload.org/download/sysjitter/sysjitter-1.4.tgz | tar -C /tmp/sysjitter -xzf - 
	make -C /tmp/sysjitter/sysjitter* && install -t /bin/ /tmp/sysjitter/sysjitter*/sysjitter 
fi

for cmd in sysjitter; do
     command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but not installed.  Aborting"; exit 1; }
done

cyccore=${cpus[0]}
cindex=1
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
 
touch ${RESULT_DIR}/sysjitter_running

echo "cmd to run: ${prefix_cmd} sysjitter --cores ${cyccore} --runtime ${RUNTIME_SECONDS} ${THRESHOLD_NS}"
${prefix_cmd} sysjitter --cores ${cyccore} --runtime ${RUNTIME_SECONDS} ${THRESHOLD_NS} > ${RESULT_DIR}/sysjitter_${RUNTIME_SECONDS}.out

rm -rf ${RESULT_DIR}/sysjitter_running

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	enable_balance
fi
