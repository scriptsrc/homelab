# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "virtual-machine" {

  # VM General Settings
  target_node = var.proxmox_node
  vmid        = var.vmid
  name        = var.vm_name
  desc        = "VM defined in terraform by copying Packer template '${var.proxmox_template_to_clone}' on proxmox"

  # VM Advanced General Settings
  onboot = true

  # VM OS Settings
  clone = var.proxmox_template_to_clone

  # VM System Settings
  agent = 1

  # VM CPU Settings
  cores   = var.vm_cpu
  sockets = 1
  cpu     = "host"

  # VM Memory Settings
  memory = var.vm_memory

  # VM Network Settings
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Add disk - but copy from proxmox template exactly
  disk {
    size    = var.vm_disk_size
    storage = "Local-Proxmox"
    format  = "raw"
    type    = "virtio"
  }

  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # (Optional) IP Address and Gateway
  # ipconfig0 = "ip=192.168.58.30/0,gw=192.168.58.1"

  # (Optional) Default User
  # ciuser = "some-user"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # ssh-rsa ... 
  # EOF

  ssh_private_key = file("../../../id_rsa")

  connection {
    type        = "ssh"
    user        = "patrick"
    private_key = self.ssh_private_key
    host        = self.ssh_host
    port        = self.ssh_port
  }

}

output "ssh_host" {
  value = proxmox_vm_qemu.virtual-machine.ssh_host
}

output "ssh_port" {
  value = proxmox_vm_qemu.virtual-machine.ssh_port
}