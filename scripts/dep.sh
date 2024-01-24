#!/bin/bash

#Pipe fails
set -euxo pipefail

#Update and Upgrade
#sudo apt update
#sudo apt upgrade -y

#Reboot
#sudo reboot
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

#Define variables
export OS=xUbuntu_22.04
export CRIO_VERSION=1.28

#Create .conf file to load modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

#Setup required sysctl paramn, these persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

#Add cri-o kubic repo
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"| sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

#Import GPG key for cri-o package repo
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

#Update and Upgrade
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 234654DA9A296436
sudo gpg --keyserver pgpkeys.mit.edu --recv-key  234654DA9A296436
sudo gpg -a --export 234654DA9A296436 | sudo apt-key add -
#sudo apt-get update -y

#Install cri-o and cri-o-runc
sudo apt install cri-o cri-o-runc cri-tools -y

#Systemd config
sudo systemctl daemon-reload
sudo systemctl start crio
sudo systemctl enable crio --now

#Add CNI plugin
#sudo apt install containernetworking-plugins -y

#Install package index for kubernetes package
#sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

#Download public signing key
#sudo mkdir -p -m 755 /etc/apt/keyrings
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

#Add kubernetes apt repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Update package index, install kubeadm, kubelet, kubectl
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#IP spec
sudo apt-get install -y jq
local_ip="$(ip --json addr show enp0s3 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
#local_ip="$(curl ifconfig.me)"
echo "Local IP Address : $local_ip"
sudo sh -c "cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF"
#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
