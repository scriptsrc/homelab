# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "splunk-indexer" {

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

  # Launch tailscale and start splunk
  provisioner "remote-exec" {
    inline = [
      "sudo tailscale up --authkey ${var.tailscale_auth_key}",
      "export FILE=splunk-9.0.2-17e00c557dc1-Linux-x86_64",
      "export URL=https://download.splunk.com/products/splunk/releases/9.0.2/linux/$FILE.tgz",
      "curl $URL --output /tmp/$FILE.tgz",
      "sudo tar xvzf /tmp/$FILE.tgz -C /opt",
      "echo \"About to fill user-seed.conf\"",
      "sudo mkdir -p /opt/splunk/etc/system/local/", # in case it doesnt exist
      # https://docs.splunk.com/Documentation/Splunk/9.0.2/Installation/StartSplunkforthefirsttime
      "echo \"[user_info]\" | sudo tee /opt/splunk/etc/system/local/user-seed.conf",
      "echo \"USERNAME = admin\" | sudo tee --append /opt/splunk/etc/system/local/user-seed.conf",
      "echo \"PASSWORD = ${var.splunk_admin_password}\" | sudo tee --append /opt/splunk/etc/system/local/user-seed.conf",
      "sudo chown -R splunk:splunk /opt/splunk",
      "sudo su splunk -c \"/opt/splunk/bin/splunk start --accept-license --no-prompt\"",
      "sudo su splunk -c \"/opt/splunk/bin/splunk enable listen 9997 -auth admin:${var.splunk_admin_password}\"",
      # "sudo /opt/splunk/bin/splunk enable boot-start -user splunk",
      # https://docs.splunk.com/Documentation/Splunk/9.0.2/Admin/ConfigureSplunktostartatboottime#Enable_boot-start_as_a_non-root_user
      # TODO: Set as a bootup service
    ]
  }
}