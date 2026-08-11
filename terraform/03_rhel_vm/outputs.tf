output "vm_id" {
  value       = proxmox_virtual_environment_vm.rhel9.vm_id
  description = "VMID auf Proxmox"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.rhel9.ipv4_addresses
  description = "Vom Guest-Agent gemeldete IPv4-Adressen"
}

output "ssh_hint" {
  value       = "ssh ansible@<ip aus ipv4_addresses>  (Key nutzen, dann sudo mit Passwort)"
  description = "Verbindungshinweis"
}
