# ---------- Proxmox-Verbindung ----------
variable "pve_endpoint" {
  type        = string
  description = "Proxmox API-URL, z.B. https://pve01.homelab.local:8006/"
}

variable "pve_api_token" {
  type        = string
  description = "API-Token: USER@REALM!TOKENID=UUID"
  sensitive   = true
}

variable "pve_insecure" {
  type        = bool
  description = "TLS-Verifikation abschalten (self-signed Cert im Homelab)"
  default     = true
}

variable "pve_ssh_username" {
  type        = string
  description = "SSH-User auf dem Proxmox-Node fuer bpg (Snippet-Upload / Disk-Import)"
  default     = "root"
}

variable "node_name" {
  type        = string
  description = "Proxmox-Node-Name, z.B. pve01"
}

# ---------- Storage ----------
variable "datastore_id" {
  type        = string
  description = "Datastore fuer VM-Disk und cloud-init-Drive, z.B. local-lvm"
  default     = "local-lvm"
}

variable "snippet_datastore_id" {
  type        = string
  description = "Datastore mit aktiviertem Content-Type 'Snippets', z.B. local"
  default     = "local"
}

variable "image_file_id" {
  type        = string
  description = "File-ID des platzierten qcow2 zum Import, z.B. local:import/rhel-9.8-x86_64-kvm.qcow2"
}

# ---------- VM-Spezifikation ----------
variable "vm_id" {
  type        = number
  description = "Feste VMID"
  default     = 931
}

variable "vm_name" {
  type        = string
  description = "VM-Name / Hostname"
  default     = "rhel9-cis01"
}

variable "vm_cpu" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type        = number
  description = "RAM in MB"
  default     = 2048
}

variable "vm_disk_size" {
  type        = number
  description = "Disk-Groesse in GB (qcow2 waechst per growpart hoch)"
  default     = 40
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_id" {
  type        = number
  description = "VLAN-Tag, null = untagged"
  default     = null
}

# ---------- Netzwerk (cloud-init) ----------
variable "use_dhcp" {
  type    = bool
  default = true
}

variable "ipv4_address" {
  type        = string
  description = "Statische IP mit CIDR, z.B. 192.168.10.31/24 (nur wenn use_dhcp=false)"
  default     = null
}

variable "ipv4_gateway" {
  type        = string
  description = "Gateway (nur wenn use_dhcp=false)"
  default     = null
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.10.1"]
}

# ---------- ansible-User ----------
variable "ansible_ssh_public_key" {
  type        = string
  description = "Public Key des ansible-Users (Inhalt der .pub-Datei, eine Zeile)"
}

variable "ansible_password_hash" {
  type        = string
  description = "SHA-512-Hash aus: openssl passwd -6"
  sensitive   = true
}

# ---------- Red Hat Subscription ----------
# Bevorzugt: Activation Key + Org (kein Passwort im Image).
# Fallback: Username/Passwort, falls dein Konto keine Activation Keys anbietet.
variable "rhsm_org_id" {
  type        = string
  description = "Red Hat Org-ID (fuer Activation Key)"
  default     = ""
}

variable "rhsm_activation_key" {
  type        = string
  description = "Red Hat Activation Key"
  default     = ""
  sensitive   = true
}

variable "rhsm_username" {
  type        = string
  description = "Fallback: RHSM-Username"
  default     = ""
}

variable "rhsm_password" {
  type        = string
  description = "Fallback: RHSM-Passwort"
  default     = ""
  sensitive   = true
}

variable "timezone" {
  type    = string
  default = "Europe/Berlin"
}
