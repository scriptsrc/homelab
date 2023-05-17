module "gpt4all-webserver" {
  source = "../generic-vm"

  # environment credentials:
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret


  vm_name   = "gpt4all-webserver"
  vmid      = 1010
  vm_cpu    = 16
  vm_memory = 32768

}

resource "null_resource" "gpt4all-webserver" {
  depends_on = [module.gpt4all-webserver]

  connection {
    type        = "ssh"
    user        = "patrick"
    private_key = file("../../../id_rsa")
    host        = module.gpt4all-webserver.ssh_host
    port        = module.gpt4all-webserver.ssh_port
  }

  provisioner "file" {
    source      = "./files/server.py"
    destination = "/tmp/server.py"
  }

  provisioner "file" {
    source      = "./files/persist.sh"
    destination = "/tmp/persist.sh"
  }

  # Launch tailscale as a subnet router:
  provisioner "remote-exec" {
    inline = [
      "sudo tailscale up --authkey ${var.tailscale_auth_key}",
      "pip install flask gpt4all-j",
      "mkdir gpt4all && cd gpt4all",
      "mv /tmp/server.py .",
      "mv /tmp/persist.sh .",
      "chmod +x persist.sh",
      "wget https://gpt4all.io/models/ggml-gpt4all-j.bin",
      "screen -dmS gpt4allwebserver ./persist.sh"
    ]
  }
}