# modules/k8s_master/main.tf

# Master Virtual Machine
module "vm" {
  source               = "../linux_vm"
  name                 = var.vm_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  network_interface_id = var.network_interface_id
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  vm_size              = var.vm_size
  tags                 = merge(var.tags, { Name = var.vm_name, Role = "master" })
}

# Provisioner to setup Kubernetes Master
resource "null_resource" "master_setup" {
  depends_on = [module.vm]

  # Trigger re-provisioning if script changes
  triggers = {
    script_hash = filemd5("${path.module}/../../kubeadm-scripts/kubeadm-master.sh")
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key_path)
    host        = var.public_ip_address
    timeout     = "30m"
  }

  # Upload the master setup script
  provisioner "file" {
    source      = "${path.module}/../../kubeadm-scripts/kubeadm-master.sh"
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
      ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.admin_username}@${var.public_ip_address} \
        "sudo kubeadm token create --print-join-command" > ${path.module}/../../join-command.txt
      echo "Join command saved to join-command.txt"
    EOT
  }
}
