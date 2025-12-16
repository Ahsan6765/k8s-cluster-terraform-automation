#!/bin/bash

# ==============================
# Kubeadm-Worker Node Setup Script
# ==============================

set -e

echo "[1/8] Updating system..."
apt-get update -y && apt-get upgrade -y

echo "[2/8] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[3/8] Installing dependencies..."
apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

echo "[4/8] Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system

echo "[5/8] Installing containerd..."
apt-get install -y containerd

echo "[6/8] Configuring containerd (SystemdCgroup=true)..."
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd
sleep 3

echo "[7/8] Adding Kubernetes v1.30 repository..."

rm -f /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "[8/8] Worker setup complete!"
echo "Now run the JOIN COMMAND from the master node:"
echo ""
echo "   kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
echo ""

echo "Worker ready to join."
