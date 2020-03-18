#!/usr/bin/bash
set -e
set -x

export REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE:-jianzzha}

PERF_OPERATOR_REPO=https://github.com/openshift-kni/performance-addon-operators.git
PERF_OPERATOR_NAMESPACE=openshift-performance-addon
PERF_OPERATOR_DIR=performance-addon-operators
WORKER_NODE=perf150

if [ ! -d "${PERF_OPERATOR_DIR}" ]; then
	sudo git clone $PERF_OPERATOR_REPO ${PERF_OPERATOR_DIR}
fi

for file in performance_profile.yaml machine_config_pool.yaml; do  
	if [ -f "$file" ]; then
		echo "overwite $file"
		/usr/bin/cp -f $file ${PERF_OPERATOR_DIR}/cluster-setup/base/performance/
	fi
done

if [ -f "deploy.sh" ]; then
	echo "overwrite deploy.sh"
	/usr/bin/cp -f deploy.sh ${PERF_OPERATOR_DIR}/hack/
fi

pushd ${PERF_OPERATOR_DIR} 
make cluster-label-worker-rt 
make cluster-deploy 
make cluster-wait-for-mcp
popd
