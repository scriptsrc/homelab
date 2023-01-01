# Ubuntu Server jammy
# ---
# Packer Template to create an Ubuntu Server (jammy) on Proxmox
# Originally from https://github.com/ChristianLempa

# Resource Definiation for the VM Template
source "proxmox" "ubuntu-server-jammy" {

  # Proxmox Connection Settings
  proxmox_url = var.proxmox_api_url
  username    = var.proxmox_api_token_id
  token       = var.proxmox_api_token_secret
  # (Optional) Skip TLS Verification
  insecure_skip_tls_verify = true

  # VM General Settings
  node                 = var.proxmox_node
  vm_id                = var.vm_template_id
  vm_name              = var.vm_template_name
  template_description = "${var.vm_template_name} Template"

  # VM OS Settings
  # (Option 1) Local ISO File
  iso_file = "local:iso/ubuntu-22.04.1-live-server-amd64.iso"
  # - or -
  # (Option 2) Download ISO
  # iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
  # iso_checksum = "84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
  # iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
  # iso_checksum = "10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"

  iso_storage_pool = "local"
  unmount_iso      = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size         = var.vm_disk_size
    format            = "raw"
    storage_pool      = "Local-Proxmox"
    storage_pool_type = "lvm"
    type              = "virtio"
  }

  # VM CPU Settings
  cores = var.vm_cpu

  # VM Memory Settings
  memory = var.vm_memory

  # VM Network Settings
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # PACKER Boot Commands
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  # PACKER Autoinstall Settings
  http_directory = "http"
  # (Optional) Bind IP Address and Port
  http_bind_address = var.packer_server_ip
  http_port_min     = 8802
  http_port_max     = 8802

  ssh_username = var.vm_template_username

  # (Option 1) Add your Password here
  # ssh_password = "your-password"
  # - or -
  # (Option 2) Add your Private SSH KEY file here
  ssh_private_key_file = "../../../id_rsa"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox.ubuntu-server-jammy"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "file" {
    source      = "files/opencanary.conf"
    destination = "/tmp/opencanary.conf"
  }

  provisioner "file" {
    source      = "files/opencanary.service"
    destination = "/etc/systemd/system/opencanary.service"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg",
      "sudo mkdir /etc/opencanaryd",
      "sudo cp /tmp/opencanary.conf /etc/opencanaryd/opencanary.conf"
    ]
  }

  # Provisioning the VM Template with Docker Installation #4
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }

  # Install tailscale #5
  # tailscale up is invoked in terraform
  provisioner "shell" {
    inline = [
      "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null",
      "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list",
      "sudo apt-get -y update",
      "sudo apt-get install -y tailscale"
    ]
  }

  # Install osquery #6
  provisioner "shell" {
    inline = [
      "export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B",
      "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY",
      "sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'",
      "sudo apt-get -y update",
      "sudo apt-get install osquery"
    ]
  }

  # Thinkst Canaries (Open Canary) #7
  # https://github.com/thinkst/opencanary
  # TODO: Make this a boot service: https://github.com/thinkst/opencanary/wiki#how-do-i-start-opencanary-on-startup
  provisioner "shell" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get install -y python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev",
      "sudo useradd -m canary",
      # "sudo apt install samba", # if you plan to use the smb module
      "sudo mkdir /opt/canaries",
      "sudo chown -R canary:canary /opt/canaries",
      "sudo su canary -c \"python3 -m venv /opt/canaries/env\"",
      "sudo su canary -c \". /opt/canaries/env/bin/activate\"",
      "sudo su canary -c \"pip install opencanary\"",
      # "pip install scapy pcapy", # optional
      "echo \"canary ALL=(ALL) NOPASSWD:ALL\" | sudo tee -a /etc/sudoers",
      # opencanaryd attempts a sudo. Previous line allows a passwordless sudo.
      "sudo su canary -c \"/home/canary/.local/bin/opencanaryd --start\""
    ]
  }

  # Install splunk forwarder #8
  # The splunk forwarder is started in terraform.
  # https://www.splunk.com/en_us/download/universal-forwarder.html
  # https://docs.splunk.com/Documentation/Forwarder/9.0.2/Forwarder/Installanixuniversalforwarder
  provisioner "shell" {
    inline = [
      "export FILE=splunkforwarder-9.0.2-17e00c557dc1-Linux-x86_64",
      "export URL=https://download.splunk.com/products/universalforwarder/releases/9.0.2/linux/$FILE.tgz",
      "export MD5URL=https://download.splunk.com/products/universalforwarder/releases/9.0.2/linux/$FILE.tgz.md5",
      "export SPLUNK_HOME=/opt/splunkforwarder",
      "sudo mkdir $SPLUNK_HOME",
      "sudo useradd -m splunk",
      # "sudo groupadd splunk",
      "sudo chown -R splunk:splunk $SPLUNK_HOME",
      "sudo su splunk -c \"curl $URL --output $SPLUNK_HOME/$FILE.tgz\"",
      "sudo su splunk -c \"curl $MD5URL --output $SPLUNK_HOME/$FILE.tgz.md5\"",
      # "cd $SPLUNK_HOME && md5sum --check $SPLUNK_HOME/$FILE.tgz.md5",
      # TODO: Fix md5sum line.
      "sudo su splunk -c \"tar xvzf $SPLUNK_HOME/$FILE.tgz -C $SPLUNK_HOME\"",
    ]
  }
}
