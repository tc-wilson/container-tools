#!/bin/bash

oc delete -f pod-intel-throughput.yaml 
oc delete -f sn-intel-west.yaml 
oc delete -f sn-intel-east.yaml 
oc delete -f policy-intel-west.yaml
oc delete -f policy-intel-east.yaml

sleep 60

pushd sriov-network-operator
make undeploy
popd
