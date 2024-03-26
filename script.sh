#!/bin/bash

sudo microk8s kubectl get po -o custom-columns="NODE-NAME":.spec.nodeName,"POD-ID":.status.podIP --no-headers > ip
sudo microk8s kubectl get po -o custom-columns="NODE-NAME":.spec.nodeName,"POD-NAMESPACE":..metadata.namespace --no-headers > ns

# Define the IPs and namespaces files
IP_FILE="ip"
NAMESPACE_FILE="ns"

# Read the IP file and create the Values.yaml content
VALUES_CONTENT="ingress:
  enabled: true
  ip:"

while IFS=' ' read -r name ip; do
  VALUES_CONTENT="$VALUES_CONTENT
    $name: $ip"
done < "$IP_FILE"

# Read the namespace file and append to the Values.yaml content
VALUES_CONTENT="$VALUES_CONTENT
  namespace:"

while IFS=' ' read -r name namespace; do
  VALUES_CONTENT="$VALUES_CONTENT
    $name: $namespace"
done < "$NAMESPACE_FILE"

# Output the generated Values.yaml content
echo "$VALUES_CONTENT" > nginx-rules/values.yaml
