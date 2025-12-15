# terraform.tfvars

# Resource Group
rg_name  = "ah-azvm-rg"
location = "East US"

# Tags
tags = {
  environment = "dev"
  project     = "azure-vm-infra"
}

# Network
vnet_name          = "ah-azvm-vnet"
vnet_address_space = ["10.0.0.0/16"]
subnet_prefixes    = ["10.0.1.0/24", "10.0.2.0/24"]

# NSG
nsg_name = "ah-azvm-nsg"

# Public IP
public_ip_name = "ah-azvm-pip"

# NIC
nic_name = "ah-azvm-nic"

# Linux VM
vm_name        = "ah-azvm-vm"
vm_size        = "Standard_B2s"
admin_username = "azureuser"
admin_password = "P@ssword1234!"   

# Path to your SSH public key file for Linux VM
# ssh_public_key_path = "~/.ssh/id_rsa.pub"


ssh_public_key_path = "C:/Users/admin/.ssh/id_rsa.pub"

# Names of VMs to create: master + workers
# vm_names = ["kmaster", "kworker1", "kworker2"]

vm_names = ["kmaster", "kworker1"]