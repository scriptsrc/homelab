module "tailscale-subnet-router" {
  source = "../generic-vm"

  # environment credentials:
  proxmox_api_url        = var.proxmox_api_url
  proxmox_api_token_id   = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret


  vm_name            = "tailscale-subnet-router-new"
  vmid               = 1000
  vm_cpu             = 2
  vm_memory          = 4096

}

resource "null_resource" "tailscale-subnet-router" {
  depends_on = [module.tailscale-subnet-router]

  connection {
    type        = "ssh"
    user        = "patrick"
    private_key = file("../../../id_rsa")
    host = module.tailscale-subnet-router.ssh_host
    port = module.tailscale-subnet-router.ssh_port
  }

  # Launch tailscale as a subnet router:
  provisioner "remote-exec" {
    inline = [
      "sudo tailscale up --advertise-routes=192.168.58.0/24 --authkey ${var.tailscale_auth_key}"
    ]
  }
}