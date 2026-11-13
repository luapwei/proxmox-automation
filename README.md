# Proxmox Automation

Infrastructure as Code für mein Homelab: Terraform provisioniert LXC-Container und VMs auf Proxmox VE, Ansible übernimmt Konfiguration und Patching.

- **01_debian_lxc:** Debian-LXC per Terraform
- **02_alma_vm:** AlmaLinux-9-VM aus Cloud-Init-Template
- **03_rhel_vm:** RHEL-9-VM mit Cloud-Init, Ansible-User und Red-Hat-Subscription, Basis für das Lab meiner Bachelorarbeit (CIS-Härtung)
- **Ansible:** Inventory und Patch-Playbooks für Debian- und RHEL-Hosts
  
Secrets werden nie committet: Zugangsdaten kommen über Umgebungsvariablen oder eine lokale terraform.tfvars, die per .gitignore ausgeschlossen ist.

## Authentifizierung (fuer alle Terraform-Ordner)

Windows (PowerShell)
```bash
$env:PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
$env:PM_API_TOKEN_SECRET=""
```

Linux
```bash
export PM_API_TOKEN_ID='terraform-prov@pve!mytoken'
export PM_API_TOKEN_SECRET=''
```

## 01_debian_lxc

```bash
cd terraform/01_debian_lxc
```

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## 02_alma_vm

### 1. Einmalig: Cloud-Init-Template auf dem Proxmox-Host anlegen

Das Skript laedt das AlmaLinux-9-Cloud-Image herunter und erstellt daraus ein
Proxmox-Template. Es muss direkt **auf dem Proxmox-Host** laufen:

```bash
scp terraform/02_alma_vm/scripts/create_template.sh root@192.168.178.10:/tmp/
ssh root@192.168.178.10 'bash /tmp/create_template.sh'
```

Storage/Bridge/VMID lassen sich per Umgebungsvariablen anpassen, z. B.:
```bash
STORAGE=local-lvm BRIDGE=vmbr0 TEMPLATE_VMID=9000 bash /tmp/create_template.sh
```

### 2. VM per Terraform aus dem Template klonen

```bash
cd terraform/02_alma_vm
```

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

Die VM bekommt standardmaessig die IP `192.168.178.31/24`. Alle Werte
(IP, Cores, RAM, Storage, SSH-Key, Passwort ...) sind in `variables.tf`
konfigurierbar bzw. per `-var`/`terraform.tfvars` ueberschreibbar.
