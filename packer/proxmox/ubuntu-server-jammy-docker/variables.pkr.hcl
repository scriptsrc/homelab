variable "packer_server_ip" {
  type        = string
  description = "IP where packer is running. Used for cloud-init"
}

variable "proxmox_node" {
  type        = string
  default     = "proxmox"
  description = "Name of the node within proxmox to run this on."
}

variable "vm_template_id" {
  type        = number
  description = "Proxmox ID for created VM Template"
  default     = 500
}

variable "vm_template_name" {
  # terraform should use this name when cloning this template.
  type        = string
  description = "Proxmox Name for created VM Template"
  default     = "ubuntu-server-jammy"
}

variable "vm_template_username" {
  type        = string
  description = "username to create on VM"
}

variable "vm_cpu" {
  type        = number
  default     = 1
  description = "Number of CPU Cores for VM Template"
}

variable "vm_memory" {
  type        = number
  default     = 2048
  description = "Memory to provide to VM Template"
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