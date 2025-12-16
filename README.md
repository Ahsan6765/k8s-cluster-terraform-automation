# Kubernetes Cluster Terraform Automation

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-326CE5?logo=kubernetes)](https://kubernetes.io/)

**Production-grade Kubernetes cluster deployment on Azure using Terraform and kubeadm with staged infrastructure provisioning.**

---

## 🎯 Features

- ✅ **Staged Deployment** - Separate master and worker infrastructure
- ✅ **Automated Setup** - Kubeadm scripts integrated with Terraform provisioners
- ✅ **Production Ready** - Calico CNI, containerd runtime, systemd cgroup driver
- ✅ **Modular Design** - Reusable Terraform modules
- ✅ **Remote State** - Azure Storage backend for state management
- ✅ **Security First** - SSH key authentication, gitignored secrets

---

## 🚀 Quick Start

### Prerequisites

- Azure CLI authenticated
- Terraform >= 1.6.0
- SSH key pair in `./ssh/` directory

### Deploy Master

```bash
cd 1-master-infra
terraform init
terraform apply
```

### Deploy Workers

```bash
cd ../2-worker-infra
terraform init
terraform apply
```

**📖 Full Documentation:** See [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 📁 Project Structure

```
├── 1-master-infra/      # Master node infrastructure
├── 2-worker-infra/      # Worker nodes infrastructure
├── modules/             # Shared Terraform modules
├── kubeadm-scripts/     # Kubernetes setup automation
└── DEPLOYMENT.md        # Detailed deployment guide
```

---

## 🏗️ Infrastructure

| Component          | Configuration                  |
| ------------------ | ------------------------------ |
| **Cloud Provider** | Microsoft Azure                |
| **Region**         | East US                        |
| **VM Size**        | Standard_B2s (2 vCPU, 4GB RAM) |
| **OS**             | Ubuntu 20.04 LTS               |
| **Kubernetes**     | v1.30 (kubeadm)                |
| **CNI**            | Calico v3.27.0                 |
| **Runtime**        | containerd                     |

---

## 🔧 Configuration

### Add More Workers

Edit `2-worker-infra/terraform.tfvars`:

```hcl
worker_vm_names = ["kworker1", "kworker2", "kworker3"]
```

### Change VM Size

Edit `1-master-infra/terraform.tfvars` or `2-worker-infra/terraform.tfvars`:

```hcl
master_vm_size = "Standard_D2s_v3"
worker_vm_size = "Standard_D2s_v3"
```

---

## 🧪 Verification

```bash
# SSH to master
ssh -i ssh/id_rsa azureuser@<master-public-ip>

# Check cluster
sudo kubectl get nodes
sudo kubectl get pods -A
```

---

## 🗑️ Cleanup

```bash
# Destroy workers first
cd 2-worker-infra && terraform destroy -auto-approve

# Then destroy master
cd ../1-master-infra && terraform destroy -auto-approve
```

---

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[k8s-dashboard-configuration.md](k8s-dashboard-configuration.md)** - Dashboard setup
- **[k8s.-deployments.md](k8s.-deployments.md)** - Sample deployments

---

## 🔒 Security

- SSH keys stored in `./ssh/` (gitignored)
- Join command in `join-command.txt` (gitignored)
- Terraform state in Azure Storage (encrypted)
- No passwords in Git history

---

## 🛠️ Technology Stack

- **IaC:** Terraform
- **Cloud:** Azure
- **Orchestration:** Kubernetes (kubeadm)
- **Networking:** Calico CNI
- **Container Runtime:** containerd
- **OS:** Ubuntu 20.04 LTS

---

## 📊 Architecture

```
Azure Cloud
└── Resource Group (ah-k8s-rg)
    └── VNet (10.0.0.0/16)
        ├── Master Node (10.0.1.4)
        │   ├── Control Plane
        │   ├── etcd
        │   └── Calico CNI
        │
        └── Worker Nodes (10.0.1.5+)
            ├── kubelet
            ├── kube-proxy
            └── Container Runtime
```

---

## 🤝 Contributing

This is a learning/development project. Feel free to fork and customize for your needs.

---

## 📝 License

This project is open source and available for educational purposes.

---

## 🆘 Support

For detailed troubleshooting, see [DEPLOYMENT.md](DEPLOYMENT.md#-troubleshooting)

---

**Author:** Ahsan Malik  
**Repository:** [k8s-cluster-terraform-automation](https://github.com/Ahsan6765/k8s-cluster-terraform-automation)  
**Last Updated:** 2025-12-15
