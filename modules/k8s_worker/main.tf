# modules/k8s_worker/main.tf

# Worker Virtual Machine
module "vm" {
  source               = "../linux_vm"
  name                 = var.vm_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  network_interface_id = var.network_interface_id
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  vm_size              = var.vm_size
  tags                 = merge(var.tags, { Name = var.vm_name, Role = "worker" })
}

# Provisioner to setup Kubernetes Worker
resource "null_resource" "worker_setup" {
  depends_on = [module.vm]

  # Trigger re-provisioning if script changes
  triggers = {
    script_hash = filemd5("${path.module}/../../kubeadm-scripts/kubeadm-worker.sh")
    vm_id       = module.vm.vm_id
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key_path)
    host        = var.public_ip_address
    timeout     = "30m"
  }

  # Upload worker setup script
  provisioner "file" {
    source      = "${path.module}/../../kubeadm-scripts/kubeadm-worker.sh"
    destination = "/tmp/kubeadm-worker.sh"
  }

  # Execute worker setup
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/kubeadm-worker.sh",
      "echo 'Starting Kubernetes worker setup...'",
      "sudo /tmp/kubeadm-worker.sh 2>&1 | tee /tmp/worker-setup.log"
    ]
  }

  # Upload and execute join command
  provisioner "file" {
    source      = var.join_command_file
    destination = "/tmp/join-command.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Joining worker to Kubernetes cluster...'",
      "sudo bash /tmp/join-command.txt",
      "echo 'Worker successfully joined the cluster!'"
    ]
  }
}
