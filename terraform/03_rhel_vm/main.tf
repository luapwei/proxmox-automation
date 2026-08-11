# cloud-init user-data als Snippet auf dem Proxmox-Node ablegen.
# Der Datastore in snippet_datastore_id muss Content-Type "Snippets" haben.
resource "proxmox_virtual_environment_file" "user_data" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.node_name

  source_raw {
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      hostname               = var.vm_name
      timezone               = var.timezone
      ansible_ssh_public_key = trimspace(var.ansible_ssh_public_key)
      ansible_password_hash  = var.ansible_password_hash
      rhsm_org_id            = var.rhsm_org_id
      rhsm_activation_key    = var.rhsm_activation_key
      rhsm_username          = var.rhsm_username
      rhsm_password          = var.rhsm_password
    })
    file_name = "${var.vm_name}-user-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "rhel9" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id
  tags      = ["terraform", "rhel9", "cis-lab"]

  # Guest-Agent an, damit Terraform die IP zurueckliest.
  agent {
    enabled = true
  }

  stop_on_destroy = true

  cpu {
    cores = var.vm_cpu
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory
  }

  # RHEL-9-qcow2 importieren. import_from referenziert das manuell
  # auf dem Node platzierte Image (siehe README, Schritt 2).
  disk {
    datastore_id = var.datastore_id
    import_from  = var.image_file_id
    interface    = "scsi0"
    size         = var.vm_disk_size
    ssd          = true
    discard      = "on"
    iothread     = true
  }

  scsi_hardware = "virtio-scsi-single"

  network_device {
    bridge  = var.network_bridge
    vlan_id = var.vlan_id
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.datastore_id
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : var.ipv4_address
        gateway = var.use_dhcp ? null : var.ipv4_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data.id
  }

  lifecycle {
    ignore_changes = [
      # cloud-init-Drive nach erstem Boot nicht dauernd neu schreiben
      initialization[0].user_data_file_id,
    ]
  }
}
