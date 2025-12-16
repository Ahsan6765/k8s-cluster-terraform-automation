output "public_ip" {
  description = "Public IP address of the worker node"
  value       = module.public_ip.ip_address
}

output "private_ip" {
  description = "Private IP address of the worker node"
  value       = module.nic.private_ip
}

output "vm_name" {
  description = "Name of the worker VM"
  value       = module.vm.vm_name
}
