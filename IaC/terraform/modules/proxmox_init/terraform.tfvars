vms = [
  {
    name       = "pfsense272"
    vmid       = 100
    memory     = 1024
    cores      = 1
    disk_size  = "8G"
    os_type    = "other"
    networks   = [
      { bridge = "vmbr01" },
      { bridge = "vmbr02" },
      { bridge = "vmbr10" },
      { bridge = "vmbr20" },
      { bridge = "vmbr30" }
    ]
    iso_file   = "local:iso/pfSense-CE-2.7.2-RELEASE-amd64.iso"
  },
  {
    name       = "lubuntu24041"
    vmid       = 101
    memory     = 1024
    cores      = 1
    disk_size  = "8G"
    os_type    = "l26"
    networks   = [
      { bridge = "vmbr01" },
      { bridge = "vmbr02" },
      { bridge = "vmbr10" },
      { bridge = "vmbr20" },
      { bridge = "vmbr30" }
    ]
    iso_file   = "local:iso/lubuntu-24.04.1-desktop-amd64.iso"
  },
  {
    name       = "ubuntu2404"
    vmid       = 102
    memory     = 2048
    cores      = 2
    disk_size  = "16G"
    os_type    = "l26"
    networks   = [
      { bridge = "vmbr10" }
    ]
    iso_file   = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
  }
]