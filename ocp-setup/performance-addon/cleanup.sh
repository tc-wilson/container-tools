#!/usr/bin/bash

PERF_OPERATOR_DIR=performance-addon-operators

if [ -d ${PERF_OPERATOR_DIR} ]; then
	pushd ${PERF_OPERATOR_DIR}
	hack/clean-deploy.sh
	echo "recover changed files in the repo"
	git checkout hack/deploy.sh
	git checkout cluster-setup/base/performance/performance_profile.yaml
	git checkout hack/wait-for-mcp.sh
	exit 0
else
	echo "can't find ${PERF_OPERATOR_DIR}, is this repo cloned under $PWD ?"
	exit 1
fi

