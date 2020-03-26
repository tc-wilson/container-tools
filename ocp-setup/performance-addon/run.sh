#!/usr/bin/bash
# env vars:
#	FULL_REGISTRY_IMAGE
#	WORKER_NODE

pause(){
 echo $1
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

export FULL_REGISTRY_IMAGE=${FULL_REGISTRY_IMAGE:-"quay.io/openshift-kni/performance-addon-operator-registry:v4.4"}
PERF_OPERATOR_REPO=https://github.com/openshift-kni/performance-addon-operators.git
PERF_OPERATOR_NAMESPACE=openshift-performance-addon
PERF_OPERATOR_DIR=performance-addon-operators

node=$(oc get nodes --selector='node-role.kubernetes.io/worker' \
    --selector='!node-role.kubernetes.io/master' -o name | head -1 | sed -e 's|^node/||')

if [ -z "${WORKER_NODE}" ]; then
	pause "env WORKER_NODE not defined! using node ${node} as RT node?"
	export WORKER_NODE=${node}
elif  ! oc get node ${WORKER_NODE}; then
	pause "node ${WORKER_NODE} is not a valid node! using node ${node} as RT node?"
	export WORKER_NODE=${node}
else
	export WORKER_NODE=${WORKER_NODE}
fi

if [ ! -d "${PERF_OPERATOR_DIR}" ]; then
	sudo git clone $PERF_OPERATOR_REPO ${PERF_OPERATOR_DIR}
fi

echo "updating ${PERF_OPERATOR_DIR}/hack/deploy.sh"
sed -i -r -e 's|^feature_dir=.*|feature_dir=cluster-setup/base/performance/|' ${PERF_OPERATOR_DIR}/hack/deploy.sh

echo "updating ${PERF_OPERATOR_DIR}/cluster-setup/base/performance/performance_profile.yaml"
if [ -f "performance_profile.yaml" ]; then
	echo "overwite ${PERF_OPERATOR_DIR}/cluster-setup/base/performance/performance_profile.yaml"
	envsubst < performance_profile.yaml > ${PERF_OPERATOR_DIR}/cluster-setup/base/performance/performance_profile.yaml
fi

echo "updating ${PERF_OPERATOR_DIR}/hack/wait-for-mcp.sh"
sed -i -r -e "s/name==\"performance-ci\"/name==\"performance-${WORKER_NODE}\"/" ${PERF_OPERATOR_DIR}/hack/wait-for-mcp.sh

pushd ${PERF_OPERATOR_DIR} 
echo "Deploying operator"
hack/deploy.sh

echo "Adding worker-rt label to node ${WORKER_NODE}"
oc label --overwrite node/${WORKER_NODE} node-role.kubernetes.io/worker-rt=""

echo "Waiting for MCP to be updated"
hack/wait-for-mcp.sh

popd
