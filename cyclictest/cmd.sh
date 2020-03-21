#!/bin/bash

# env vars:
#	DURATION (default "24h")
#	DISABLE_CPU_BALANCE (default "n", choice y/n)
#	stress_tool (default "false", choices false/stress-ng/rteval)
#	rt_priority (default "99")

source common-libs/functions.sh

function sigfunc() {
        tmux kill-session -t stress 2>/dev/null
	rm -rf {RESULT_DIR}/cyclictest_running
	if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
		enable_balance
	fi
	exit 0
}

echo "############# dumping env ###########"
env
echo "#####################################"

echo "**** uid: $UID ****"
if [[ -z "${DURATION}" ]]; then
	DURATION="24h"
fi

if [[ -z "${RESULT_DIR}" ]]; then
	RESULT_DIR="/tmp/cyclictest"
fi

if [[ -z "${stress_tool}" ]]; then
	stress="false"
elif [[ "${stress_tool}" != "stress-ng" && "${stress_tool}" != "rteval" ]]; then
	stress="false"
else
	stress=${stress_tool}
fi

if [[ -z "${rt_priority}" ]]; then
        rt_priority=99
elif [[ "${rt_priority}" =~ ^[0-9]+$ ]]; then
	if (( rt_priority > 99 )); then
		rt_priority=99
	fi
else
	rt_priority=99
fi

# make sure the dir exists
[ -d ${RESULT_DIR} ] || mkdir -p ${RESULT_DIR} 

release=$(cat /etc/os-release | sed -n -r 's/VERSION_ID="(.).*/\1/p')

# remove existing cyclictest package and replace with centos7 version in stead
yum -y remove rt-tests
cat <<EOF >/etc/yum.repos.d/CentOS-rt.repo
[rt]
name=CentOS-7-rt
baseurl=http://mirror.centos.org/centos/7/rt/x86_64/
gpgcheck=0
EOF
yum install -y rt-tests

for cmd in tmux cyclictest; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but not installed. Aborting"; exit 1; }
done

cpulist=`get_allowed_cpuset`
echo "allowed cpu list: ${cpulist}"

cpulist=`convert_number_range ${cpulist} | tr , '\n' | sort -n | uniq`

declare -a cpus
cpus=(${cpulist})

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	disable_balance
fi

trap sigfunc TERM INT SIGUSR1

# stress run in each tmux window per cpu
if [[ "$stress" == "stress-ng" ]]; then
    yum install -y stress-ng 2>&1 || { echo >&2 "stress-ng required but install failed. Aborting"; sleep infinity; }
    tmux new-session -s stress -d
    for w in $(seq 1 ${#cpus[@]}); do
        tmux new-window -t stress -n $w "taskset -c ${cpus[$(($w-1))]} stress-ng --cpu 1 --cpu-load 100 --cpu-method loop"
    done
fi

if [[ "$stress" == "rteval" ]]; then
	tmux new-session -s stress -d "rteval -v --onlyload"
fi

cyccore=${cpus[0]}
cindex=1
ccount=1
while (( $cindex < ${#cpus[@]} )); do
	cyccore="${cyccore},${cpus[$cindex]}"
	cindex=$(($cindex + 1))
        ccount=$(($ccount + 1))
done

touch ${RESULT_DIR}/cyclictest_running

extra_opt=""
if [[ "$release" = "7" ]]; then
    extra_opt="${extra_opt} -n"
fi

echo "running cmd: cyclictest -q -D ${DURATION} -p ${rt_priority} -t ${ccount} -a ${cyccore} -h 30 -m ${extra_opt}"
cyclictest -q -D ${DURATION} -p ${rt_priority} -t ${ccount} -a ${cyccore} -h 30 -m ${extra_opt} > ${RESULT_DIR}/cyclictest_${DURATION}.out

# kill stress before exit 
tmux kill-session -t stress 2>/dev/null
rm -rf ${RESULT_DIR}/cyclictest_running

if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
	enable_balance
fi

