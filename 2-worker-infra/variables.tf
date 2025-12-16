# 2-worker-infra/variables.tf

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# Worker VMs
variable "worker_vm_names" {
  type        = list(string)
  description = "List of worker VM names to create"
  default     = ["kworker1"]
}

variable "worker_vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Size of the worker Virtual Machines"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VMs"
}

# SSH Keys
variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file for the Linux VMs"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key file for provisioner authentication"
}
