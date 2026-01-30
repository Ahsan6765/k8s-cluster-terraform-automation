# Kubernetes Cluster Deployment Guide

## 🎯 Overview

This project provides **staged Terraform deployment** for a production-grade Kubernetes cluster on Azure using **kubeadm**. The infrastructure is split into two phases:

1. **Phase 1:** Master node deployment with automated cluster initialization
2. **Phase 2:** Worker node deployment with automated cluster joining

---

## 📁 Project Structure

```
k8s-terraform-automation/
├── 1-master-infra/          # Master node infrastructure
│   ├── main.tf              # Master VM + provisioners
│   ├── variables.tf         # Master variables
│   ├── terraform.tfvars     # Master configuration (gitignored)
│   ├── outputs.tf           # Master outputs
│   └── provider.tf          # Azure provider config
│
├── 2-worker-infra/          # Worker nodes infrastructure
│   ├── main.tf              # Worker VMs + provisioners
│   ├── variables.tf         # Worker variables
│   ├── terraform.tfvars     # Worker configuration (gitignored)
│   ├── outputs.tf           # Worker outputs
│   └── provider.tf          # Azure provider config
│
├── modules/                 # Shared Terraform modules
│   ├── resource_group/
│   ├── network/
│   ├── nsg/
│   ├── public_ip/
│   ├── nic/
│   └── linux_vm/
│
├── kubeadm-scripts/         # Kubernetes setup scripts
│   ├── kubeadm-master.sh    # Master initialization
│   └── kubeadm-worker.sh    # Worker setup
│
├── ssh/                     # SSH keys (gitignored)
│   ├── id_rsa
│   └── id_rsa.pub
│
└── join-command.txt         # Generated join command (gitignored)
```

---

## 🚀 Deployment Workflow

### **Prerequisites**

1. **Azure CLI** installed and authenticated

   ```bash
   az login
   az account set --subscription "adc9f320-e56e-45b1-845e-c73484745fc8"
   ```

2. **Terraform** >= 1.6.0 installed

   ```bash
   terraform version
   ```

3. **SSH Key Pair** generated

   ```bash
   ssh-keygen -t rsa -b 4096 -f ./ssh/id_rsa -N ""
   ```

4. **Azure Backend** configured (already exists)
   - Resource Group: `ah-db-rg`
   - Storage Account: `tfstate1234512`
   - Container: `k3s-cluster-infra`

---

### **Phase 1: Deploy Master Node**

#### Step 1: Navigate to master infrastructure

```bash
cd 1-master-infra
```

#### Step 2: Initialize Terraform

```bash
terraform init
```

#### Step 3: Review the plan

```bash
terraform plan
```

**Expected resources:**

- 1 Resource Group
- 1 Virtual Network with 2 subnets
- 1 Network Security Group
- 1 Public IP (master)
- 1 Network Interface (master)
- 1 Linux VM (kmaster)
- Provisioners for kubeadm setup

#### Step 4: Deploy master infrastructure

```bash
terraform apply
```

**⏱️ Deployment Time:** ~20-25 minutes

- Infrastructure creation: ~5 minutes
- Kubeadm master setup: ~15-20 minutes

#### Step 5: Verify master deployment

**Check Terraform outputs:**

```bash
terraform output
```

**Expected output:**

```
master_public_ip = "20.185.80.86"
master_private_ip = "10.0.1.4"
join_command_file = "../join-command.txt"
```

**Verify join command file:**

```bash
cat ../join-command.txt
```

**Should contain:**

```
kubeadm join 10.0.1.4:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

#### Step 6: SSH to master and verify cluster

```bash
# Get master public IP
MASTER_IP=$(terraform output -raw master_public_ip)

# SSH to master
ssh -i ../ssh/id_rsa azureuser@$MASTER_IP

# Check cluster status
sudo kubectl get nodes
sudo kubectl get pods -A
```

**Expected output:**

```
NAME      STATUS   ROLES           AGE   VERSION
kmaster   Ready    control-plane   5m    v1.30.x
```

---

### **Phase 2: Deploy Worker Nodes**

#### Step 1: Navigate to worker infrastructure

```bash
cd ../2-worker-infra
```

#### Step 2: Initialize Terraform

```bash
terraform init
```

#### Step 3: Review the plan

```bash
terraform plan
```

**Expected resources:**

- 1 Public IP per worker
- 1 Network Interface per worker
- 1 Linux VM per worker
- Provisioners for kubeadm setup and cluster join

#### Step 4: Deploy worker infrastructure

```bash
terraform apply
```

**⏱️ Deployment Time:** ~15-20 minutes per worker

- Infrastructure creation: ~5 minutes
- Kubeadm worker setup: ~10 minutes
- Cluster join: ~2 minutes

#### Step 5: Verify worker deployment

**Check Terraform outputs:**

```bash
terraform output
```

**Expected output:**

```
worker_public_ips = {
  "kworker1" = "20.185.80.87"
}
cluster_info = {
  "master_ip" = "20.185.80.86"
  "resource_group" = "ah-k8s-rg"
  "worker_count" = 1
}
```

#### Step 6: Verify cluster formation

**SSH to master:**

```bash
MASTER_IP=$(cd ../1-master-infra && terraform output -raw master_public_ip)
ssh -i ../ssh/id_rsa azureuser@$MASTER_IP
```

**Check all nodes:**

```bash
sudo kubectl get nodes -o wide
```

**Expected output:**

```
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP
kmaster    Ready    control-plane   30m   v1.30.x   10.0.1.4      20.185.80.86
kworker1   Ready    <none>          10m   v1.30.x   10.0.1.5      20.185.80.87
```

**Verify all pods are running:**

```bash
sudo kubectl get pods -A
```

---

## 🧪 Testing the Cluster

### Deploy a test application

**Create nginx deployment:**

```bash
sudo kubectl create deployment nginx --image=nginx --replicas=2
sudo kubectl expose deployment nginx --port=80 --type=NodePort
```

**Check deployment:**

```bash
sudo kubectl get deployments
sudo kubectl get pods
sudo kubectl get svc nginx
```

**Access nginx:**

```bash
# Get NodePort
NODE_PORT=$(sudo kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')

# Access via any node IP
curl http://10.0.1.4:$NODE_PORT
curl http://10.0.1.5:$NODE_PORT
```

---

## 🔧 Configuration

### Adding More Workers

**Edit `2-worker-infra/terraform.tfvars`:**

```hcl
worker_vm_names = ["kworker1", "kworker2", "kworker3"]
```

**Apply changes:**

```bash
cd 2-worker-infra
terraform apply
```

### Changing VM Sizes

**For master (`1-master-infra/terraform.tfvars`):**

```hcl
master_vm_size = "Standard_D2s_v3"  # 2 vCPUs, 8GB RAM
```

**For workers (`2-worker-infra/terraform.tfvars`):**

```hcl
worker_vm_size = "Standard_D2s_v3"
```

---

## 🗑️ Cleanup

### Destroy worker infrastructure first

```bash
cd 2-worker-infra
terraform destroy -auto-approve
```

### Then destroy master infrastructure

```bash
cd ../1-master-infra
terraform destroy -auto-approve
```

**⚠️ Important:** Always destroy workers before master to avoid orphaned resources.

---

## 🔒 Security Notes

1. **SSH Keys:** Never commit `ssh/` directory to Git
2. **Join Command:** `join-command.txt` contains cluster secrets - excluded from Git
3. **tfvars Files:** Contain sensitive configuration - excluded from Git
4. **Token Expiration:** Join tokens expire after 24 hours

**To regenerate join command:**

```bash
ssh -i ssh/id_rsa azureuser@<master-ip> \
  "sudo kubeadm token create --print-join-command" > join-command.txt
```

---

## 🐛 Troubleshooting

### Master setup fails

**Check logs:**

```bash
ssh -i ssh/id_rsa azureuser@<master-ip>
cat /tmp/master-setup.log
```

### Worker fails to join

**Regenerate join command:**

```bash
ssh -i ssh/id_rsa azureuser@<master-ip> \
  "sudo kubeadm token create --print-join-command" > join-command.txt
```

**Re-run worker provisioner:**

```bash
cd 2-worker-infra
terraform taint 'null_resource.worker_setup["kworker1"]'
terraform apply
```

### SSH connection timeout

**Check NSG rules:**

```bash
az network nsg rule list \
  --resource-group ah-k8s-rg \
  --nsg-name ah-k8s-nsg \
  --output table
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│                  Azure Cloud                     │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │     Resource Group: ah-k8s-rg              │ │
│  │                                            │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │   VNet: 10.0.0.0/16                  │ │ │
│  │  │                                      │ │ │
│  │  │  ┌────────────┐    ┌────────────┐   │ │ │
│  │  │  │  kmaster   │    │  kworker1  │   │ │ │
│  │  │  │ 10.0.1.4   │◄───┤ 10.0.1.5   │   │ │ │
│  │  │  │ Public IP  │    │ Public IP  │   │ │ │
│  │  │  └────────────┘    └────────────┘   │ │ │
│  │  │                                      │ │ │
│  │  │  Calico CNI: 192.168.0.0/16         │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

---

## 📝 Next Steps

1. **Install Kubernetes Dashboard** - See `k8s-dashboard-configuration.md`
2. **Setup Ingress Controller** - Nginx or Traefik
3. **Configure Monitoring** - Prometheus + Grafana
4. **Implement GitOps** - ArgoCD or Flux
5. **Add Persistent Storage** - Azure Disk or Azure Files

---

## 🆘 Support

For issues or questions:

1. Check troubleshooting section above
2. Review Terraform logs: `terraform show`
3. Check Azure Portal for resource status
4. Review kubeadm logs on VMs

---

**Last Updated:** 2025-12-15  
**Terraform Version:** >= 1.6.0  
**Kubernetes Version:** 1.30.x  
**Azure Provider:** ~> 4.0
