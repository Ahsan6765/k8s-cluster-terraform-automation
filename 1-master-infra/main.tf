# 1-master-infra/main.tf

# Resource Group
module "resource_group" {
  source   = "../modules/resource_group"
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

# Virtual Network + Subnets
module "network" {
  source              = "../modules/network"
  vnet_name           = var.vnet_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  tags                = var.tags
}

# Network Security Group
module "nsg" {
  source              = "../modules/nsg"
  nsg_name            = var.nsg_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
  subnet_ids          = module.network.subnet_ids
}

# Public IP for Master
module "master_public_ip" {
  source              = "../modules/public_ip"
  name                = "${var.master_vm_name}-pip"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  tags                = merge(var.tags, { Name = "${var.master_vm_name}-pip", Role = "master" })
}

# Network Interface for Master
module "master_nic" {
  source              = "../modules/nic"
  name                = "${var.master_vm_name}-nic"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.subnet_ids[0]
  public_ip_id        = module.master_public_ip.id
  tags                = merge(var.tags, { Name = "${var.master_vm_name}-nic", Role = "master" })
}

# Master Virtual Machine
module "master_vm" {
  source               = "../modules/linux_vm"
  name                 = var.master_vm_name
  location             = module.resource_group.location
  resource_group_name  = module.resource_group.name
  network_interface_id = module.master_nic.id
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  vm_size              = var.master_vm_size
  tags                 = merge(var.tags, { Name = var.master_vm_name, Role = "master" })
}

# Provisioner to setup Kubernetes Master
resource "null_resource" "master_setup" {
  depends_on = [module.master_vm]

  # Trigger re-provisioning if script changes
  triggers = {
    script_hash = filemd5("../kubeadm-scripts/kubeadm-master.sh")
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key_path)
    host        = module.master_public_ip.ip_address
    timeout     = "30m"
  }

  # Upload the master setup script
  provisioner "file" {
    source      = "../kubeadm-scripts/kubeadm-master.sh"
    destination = "/tmp/kubeadm-master.sh"
  }

  # Execute the master setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm-master.sh",
      "echo 'Starting Kubernetes master setup...'",
      "sudo /tmp/kubeadm-master.sh 2>&1 | tee /tmp/master-setup.log",
      "echo 'Master setup completed!'"
    ]
  }

  # Extract join command and save locally
  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.admin_username}@${module.master_public_ip.ip_address} \
        "sudo kubeadm token create --print-join-command" > ${path.module}/../join-command.txt
      echo "Join command saved to join-command.txt"
    EOT
  }
}
