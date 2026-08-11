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

# Klont die AlmaLinux-9-VM aus dem Cloud-Init-Template.
# Template vorher einmalig mit scripts/create_template.sh erstellen.
resource "proxmox_vm_qemu" "almalinux" {
  target_node = "pve01"
  name        = "almalinux-9"

  clone      = "almalinux-9-cloud"
  full_clone = true

  agent   = 1
  os_type = "cloud-init"
  cores   = 1
  memory  = 2048
  scsihw  = "virtio-scsi-single"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = "10G"
          storage = "local-lvm"
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial {
    id   = 0
    type = "socket"
  }

  # Cloud-Init
  ciuser     = "root"
  cipassword = var.ci_password
  ipconfig0  = "ip=192.168.178.31/24,gw=192.168.178.1"
  nameserver = "192.168.178.1"
}
