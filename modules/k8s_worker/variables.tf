variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "network_interface_id" {
  description = "ID of the network interface for the worker"
  type        = string
}

variable "public_ip_address" {
  description = "Public IP address for SSH access"
  type        = string
}

variable "vm_name" {
  description = "Name of the worker VM"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key"
  type        = string
}

variable "join_command_file" {
  description = "Path to the file containing the kubeadm join command"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
