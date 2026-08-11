terraform {
  required_version = ">= 1.0.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.178.10:8006/api2/json"
  pm_tls_insecure = true
}

resource "proxmox_lxc" "simple_lxc" {
  target_node  = "pve01"
  hostname     = "lxc-basic"
  ostemplate   = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  ostype       = "debian"
  unprivileged = true
  start        = true
  cores        = 1
  password     = var.lxc_password

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.178.25/24"
    gw     = "192.168.178.1"
  }
}