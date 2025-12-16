output "public_ip" {
  description = "Public IP address of the master node"
  value       = module.public_ip.ip_address
}

output "private_ip" {
  description = "Private IP address of the master node"
  value       = module.nic.private_ip
}

output "vm_name" {
  description = "Name of the master VM"
  value       = module.vm.vm_name
}
