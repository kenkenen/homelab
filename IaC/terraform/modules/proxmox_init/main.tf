provider "proxmox" {
  pm_api_url    = "https://192.168.4.2:8006/api2/json"
  pm_user       = var.pm_user
  pm_password   = var.pm_password
  pm_tls_insecure = true
}

variable "pm_user" {
  description = "Proxmox user"
  type        = string
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
}

variable "vms" {
  description = "List of VMs to create"
  type = list(object({
    name       = string
    vmid       = number
    memory     = number
    cores      = number
    disk_size  = string
    os_type    = string
    networks   = list(object({
      bridge = string
    }))
    iso_file   = string
  }))
}

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  count = length(var.vms)

  name       = var.vms[count.index].name
  vmid       = var.vms[count.index].vmid
  memory     = var.vms[count.index].memory
  cores      = var.vms[count.index].cores
  scsihw     = "virtio-scsi-pci"
  bootdisk   = "scsi0"
  agent      = 1
  os_type    = var.vms[count.index].os_type
  target_node = "pve"  # Replace with the actual hostname or IP address of your Proxmox node
  boot        = "order=ide2;scsi0"

  disk {
    size         = var.vms[count.index].disk_size
    type         = "scsi"
    storage      = "local-lvm"
  }

  iso = "${var.vms[count.index].iso_file}"

  dynamic "network" {
    for_each = var.vms[count.index].networks
    content {
      model   = "virtio"
      bridge  = network.value.bridge
    }
  }

  lifecycle {
    ignore_changes = [
      network,
      disk
    ]
  }
}