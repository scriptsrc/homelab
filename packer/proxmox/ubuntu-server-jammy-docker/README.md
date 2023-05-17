Builds the Proxmox Template for VMs to use as a base/foundation.

1. Update the `credentials.auto.pkrvars.hcl` file:

```
proxmox_api_url          = "https://192.168.58.X:8006/api2/json"
proxmox_api_token_id     = "user@pam!token_name"
proxmox_api_token_secret = "000000000000000000000000000000000000"
packer_server_ip         = "192.168.1.X"
vm_template_id           = 500
vm_template_name         = "foundation-ami"
vm_template_username     = "your-username"
vm_cpu                   = 4
vm_memory                = 8096
vm_disk_size             = "32G"
```
**Note! - Make sure the packer_server_ip is updated!**

<hr>

2. Add an `id_rsa` for packer to use and make sure the `files\http\user-data` has a corresponding `id_rsa.pub`.
<hr>

3. Format, validate, and build your VM Template:
```
PS C:\...\github\homelab\packer\proxmox\ubuntu-server-jammy-docker

> ..\..\..\..\..\packer.exe fmt .
> ..\..\..\..\..\packer.exe validate .
> ..\..\..\..\..\packer.exe build .
```