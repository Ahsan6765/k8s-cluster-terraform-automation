#!/bin/bash

# ==============================
#  Kubeadm-Master Node Setup Script
# ==============================

set -e

echo "[1/12] Updating system..."
apt-get update -y && apt-get upgrade -y

echo "[2/12] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[3/12] Installing dependencies..."
apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

echo "[4/12] Loading kernel modules..."
modprobe overlay
modprobe br_netfilter
cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system

echo "[5/12] Installing containerd..."
apt-get install -y containerd

echo "[6/12] Configuring containerd (SystemdCgroup=true)..."
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd
sleep 3

echo "[7/12] Setting up Kubernetes v1.30 repository..."

rm -f /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF

echo "[8/12] Installing kubeadm, kubelet, kubectl v1.30..."
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "[9/12] Initializing Kubernetes cluster..."
kubeadm init --pod-network-cidr=192.168.0.0/16

echo "[10/12] Setting up kubeconfig for root and current user..."
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "[11/12] Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "[12/12] Retrieving worker join command..."
echo "================================================="
echo " COPY BELOW COMMAND TO JOIN WORKERS "
echo "================================================="
kubeadm token create --print-join-command
echo "================================================="

echo "Master setup completed successfully."
