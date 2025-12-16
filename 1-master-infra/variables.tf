# 1-master-infra/variables.tf

variable "rg_name" {
  type        = string
  description = "Name of the Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# Network
variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
}

variable "subnet_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnets"
}

# NSG
variable "nsg_name" {
  type        = string
  description = "Name of the Network Security Group"
}

# Master VM
variable "master_vm_name" {
  type        = string
  description = "Name of the master VM"
  default     = "kmaster"
}

variable "master_vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Size of the master Virtual Machine"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
}

# SSH Keys
variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file for the Linux VM"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key file for provisioner authentication"
}
