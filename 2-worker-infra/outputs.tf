# 2-worker-infra/outputs.tf

output "worker_public_ips" {
  description = "Public IP addresses of worker nodes"
  value       = { for k, v in module.worker_public_ip : k => v.ip_address }
}

output "worker_private_ips" {
  description = "Private IP addresses of worker nodes"
  value       = { for k, v in module.worker_nic : k => v.private_ip }
}

output "worker_vm_names" {
  description = "Names of worker VMs"
  value       = var.worker_vm_names
}

output "cluster_info" {
  description = "Cluster information"
  value = {
    master_ip      = data.terraform_remote_state.master.outputs.master_public_ip
    worker_count   = length(var.worker_vm_names)
    resource_group = data.terraform_remote_state.master.outputs.resource_group_name
  }
}
