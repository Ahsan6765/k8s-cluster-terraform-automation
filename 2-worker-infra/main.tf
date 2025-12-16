# 2-worker-infra/main.tf

# Data source to read master infrastructure outputs
data "terraform_remote_state" "master" {
  backend = "azurerm"

  config = {
    resource_group_name  = "ah-db-rg"
    storage_account_name = "tfstate1234512"
    container_name       = "k3s-cluster-infra"
    key                  = "master.terraform.tfstate"
  }
}

# Public IPs for Workers
module "worker_public_ip" {
  for_each            = toset(var.worker_vm_names)
  source              = "../modules/public_ip"
  name                = "${each.value}-pip"
  location            = data.terraform_remote_state.master.outputs.location
  resource_group_name = data.terraform_remote_state.master.outputs.resource_group_name
  allocation_method   = "Static"
  tags                = merge(var.tags, { Name = "${each.value}-pip", Role = "worker" })
}

# Network Interfaces for Workers
module "worker_nic" {
  for_each            = toset(var.worker_vm_names)
  source              = "../modules/nic"
  name                = "${each.value}-nic"
  location            = data.terraform_remote_state.master.outputs.location
  resource_group_name = data.terraform_remote_state.master.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.master.outputs.subnet_ids[0]
  public_ip_id        = module.worker_public_ip[each.value].id
  tags                = merge(var.tags, { Name = "${each.value}-nic", Role = "worker" })
}

# Worker Virtual Machines
module "worker_vm" {
  for_each             = toset(var.worker_vm_names)
  source               = "../modules/linux_vm"
  name                 = each.value
  location             = data.terraform_remote_state.master.outputs.location
  resource_group_name  = data.terraform_remote_state.master.outputs.resource_group_name
  network_interface_id = module.worker_nic[each.value].id
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  vm_size              = var.worker_vm_size
  tags                 = merge(var.tags, { Name = each.value, Role = "worker" })
}

# Provisioner to setup Kubernetes Workers
resource "null_resource" "worker_setup" {
  for_each   = toset(var.worker_vm_names)
  depends_on = [module.worker_vm]

  # Trigger re-provisioning if script changes
  triggers = {
    script_hash = filemd5("../kubeadm-scripts/kubeadm-worker.sh")
    vm_id       = module.worker_vm[each.value].vm_id
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key_path)
    host        = module.worker_public_ip[each.value].ip_address
    timeout     = "30m"
  }

  # Upload the worker setup script
  provisioner "file" {
    source      = "../kubeadm-scripts/kubeadm-worker.sh"
    destination = "/tmp/kubeadm-worker.sh"
  }

  # Execute the worker setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm-worker.sh",
      "echo 'Starting Kubernetes worker setup...'",
      "sudo /tmp/kubeadm-worker.sh 2>&1 | tee /tmp/worker-setup.log",
      "echo 'Worker setup completed!'"
    ]
  }

  # Upload and execute join command
  provisioner "file" {
    source      = "../join-command.txt"
    destination = "/tmp/join-command.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Joining worker to Kubernetes cluster...'",
      "sudo bash /tmp/join-command.txt",
      "echo 'Worker successfully joined the cluster!'"
    ]
  }
}
