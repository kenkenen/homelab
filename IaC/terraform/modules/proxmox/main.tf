provider "proxmox" {
  pm_api_url    = "https://192.168.4.2:8006/api2/json"
  pm_user       = var.pm_user
  pm_password   = var.pm_password
  pm_tls_insecure = true
}

variable "pm_user" {
  description = "Proxmox user"
  type        = string
  default     = ""
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
  default     = ""
}

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}