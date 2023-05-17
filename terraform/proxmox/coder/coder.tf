module "coder" {
  source = "../generic-vm"

  # environment credentials:
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret


  vm_name   = "coder"
  vmid      = 1020
  vm_cpu    = 16
  vm_memory = 32768

}

resource "null_resource" "coder" {
  depends_on = [module.coder]

  connection {
    type        = "ssh"
    user        = "patrick"
    private_key = file("../../../id_rsa")
    host        = module.coder.ssh_host
    port        = module.coder.ssh_port
  }

  # 1) Launch tailscale:
  # 2) Install coder:
  provisioner "remote-exec" {
    inline = [
      "sudo tailscale up --authkey ${var.tailscale_auth_key}",

      "sudo apt-get update && sudo apt-get install -y gnupg software-properties-common",
      "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update",
      "sudo apt-get install terraform",
      
      "sudo curl -fsSL https://coder.com/install.sh | sudo sh",
      "sudo systemctl enable --now coder"

    ]
  }
}