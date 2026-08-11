terraform {
  required_version = ">= 1.5"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
  # API-Token-Format: "USER@REALM!TOKENID=UUID"
  api_token = var.pve_api_token
  insecure  = var.pve_insecure

  # bpg braucht SSH zum Node, um Snippets hochzuladen und das qcow2 zu importieren.
  # Der SSH-User muss auf dem Proxmox-Host sudo-Rechte haben.
  ssh {
    agent    = true
    username = var.pve_ssh_username
  }
}
