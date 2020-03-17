#!/bin/bash

oc delete -f pod-mlx-throughput.yaml 
oc delete -f sn-mlx-west.yaml 
oc delete -f sn-mlx-east.yaml 
oc delete -f policy-mlx-west.yaml
oc delete -f policy-mlx-east.yaml

sleep 60

pushd sriov-network-operator
make undeploy
popd
