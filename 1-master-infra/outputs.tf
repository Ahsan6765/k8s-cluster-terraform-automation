# 1-master-infra/outputs.tf

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = module.network.subnet_ids
}

output "master_public_ip" {
  description = "Public IP address of the master node"
  value       = module.master_public_ip.ip_address
}

output "master_private_ip" {
  description = "Private IP address of the master node"
  value       = module.master_nic.private_ip
}

output "master_vm_name" {
  description = "Name of the master VM"
  value       = module.master_vm.vm_name
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "join_command_file" {
  description = "Path to the join command file"
  value       = "${path.module}/../join-command.txt"
}
