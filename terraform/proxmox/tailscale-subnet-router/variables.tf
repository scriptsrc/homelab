variable "proxmox_node" {
  type        = string
  default     = "proxmox"
  description = "Name of the node within proxmox to run this on."
}

variable "vmid" {
  type        = number
  default     = 601
  description = "ID of the Proxmox VM to create"
}

variable "vm_name" {
  type        = string
  default     = "vm-ubuntu-server-jammy-tf"
  description = "name of the VM to create"
}

variable "proxmox_template_to_clone" {
  type        = string
  default     = "ubuntu-server-jammy"
  description = "Name of the Proxmox template we will be cloning."
}

variable "vm_cpu" {
  type        = number
  default     = 1
  description = "Number of CPU Cores for VM"
}

variable "vm_memory" {
  type        = number
  default     = 2048
  description = "Memory to provide to VM"
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}