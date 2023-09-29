#!/bin/sh

#Status of pods
kubectl get po -n kube-system

#Cluster component health
kubectl get --raw='/readyz?verbose'

#Cluster info
kubectl cluster-info

#Check if worker nodes are added to control panel
kubectl get nodes

#Change label of worker nodes
kubectl label node worker-node01 node-role.kubernetes.io/worker=<worker>

#Verify metrics 
kubectl top nodes
