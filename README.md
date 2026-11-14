# Proxmox Automation

Infrastructure as Code für mein Homelab: Terraform provisioniert LXC-Container und VMs auf Proxmox VE, Ansible übernimmt Konfiguration und Patching.

- **01_debian_lxc:** Debian-LXC per Terraform
- **02_alma_vm:** AlmaLinux-9-VM aus Cloud-Init-Template
- **03_rhel_vm:** RHEL-9-VM mit Cloud-Init, Ansible-User und Red-Hat-Subscription, Basis für das Lab meiner Bachelorarbeit (CIS-Härtung)
- **Ansible:** Beispiel-Inventory und Patch-Playbooks für Debian- und RHEL-Hosts

Secrets werden nie committet: Zugangsdaten kommen über Umgebungsvariablen oder eine lokale terraform.tfvars, die per .gitignore ausgeschlossen ist.

## Voraussetzungen

- Terraform >= 1.5
- Ansible (für die Playbooks)
- Proxmox-API-Token mit passenden Rechten

## Authentifizierung

Die Ordner nutzen zwei verschiedene Provider, die sich unterschiedlich
authentifizieren.

### 01_debian_lxc und 02_alma_vm (telmate/proxmox)

Das API-Token wird über Umgebungsvariablen übergeben. Die API-URL steht fest
in `main.tf` (`pm_api_url`) und muss bei Bedarf angepasst werden.

Windows (PowerShell)
```powershell
$env:PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
$env:PM_API_TOKEN_SECRET="<token-secret>"
```

Linux
```bash
export PM_API_TOKEN_ID='terraform-prov@pve!mytoken'
export PM_API_TOKEN_SECRET='<token-secret>'
```

### 03_rhel_vm (bpg/proxmox)

Endpoint und Token stehen in `terraform.tfvars` (Variablen `pve_endpoint` und
`pve_api_token`). Das Token hat das Format `USER@REALM!TOKENID=UUID`. Die
Umgebungsvariablen `PM_API_TOKEN_*` werden hier nicht verwendet.

Zusätzlich braucht der Provider SSH-Zugriff auf den Proxmox-Node, um Snippets
hochzuladen und das Image zu importieren. Der Key muss im `ssh-agent` geladen
sein, der Benutzer wird über `pve_ssh_username` gesetzt (Standard `root`).

## 01_debian_lxc

Das Root-Passwort des Containers kommt aus `terraform.tfvars`:

```bash
cd terraform/01_debian_lxc
cp terraform.tfvars.example terraform.tfvars   # Passwort eintragen
```

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## 02_alma_vm

### 1. Einmalig: Cloud-Init-Template auf dem Proxmox-Host anlegen

Das Skript lädt das AlmaLinux-9-Cloud-Image herunter und erstellt daraus ein
Proxmox-Template. Es muss direkt **auf dem Proxmox-Host** laufen:

```bash
scp terraform/02_alma_vm/scripts/create_template.sh root@192.168.178.10:/tmp/
ssh root@192.168.178.10 'bash /tmp/create_template.sh'
```

Storage, Bridge und VMID lassen sich per Umgebungsvariablen anpassen, z. B.:
```bash
STORAGE=local-lvm BRIDGE=vmbr0 TEMPLATE_VMID=9000 bash /tmp/create_template.sh
```

### 2. VM per Terraform aus dem Template klonen

```bash
cd terraform/02_alma_vm
cp terraform.tfvars.example terraform.tfvars   # Passwort eintragen
```

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

Die VM bekommt die IP `192.168.178.31/24`. IP, Cores, RAM und Storage sind in
`main.tf` gesetzt, das Root-Passwort kommt über die Variable `ci_password`.

## 03_rhel_vm

Erstellt eine RHEL-9-VM aus dem offiziellen KVM-Guest-Image. cloud-init legt
den Benutzer `ansible` an und registriert das System bei Red Hat.

### 1. Datastore für Snippets vorbereiten

Die cloud-init-Konfiguration wird als Snippet auf dem Node abgelegt. Der
Datastore aus `snippet_datastore_id` (Standard `local`) muss den Content-Type
**Snippets** haben: in der GUI unter *Datacenter > Storage > local > Bearbeiten
> Inhalt* aktivieren.

### 2. qcow2-Image auf dem Node ablegen

Das RHEL-9-KVM-Guest-Image (`rhel-9.x-x86_64-kvm.qcow2`) aus dem Red Hat
Customer Portal herunterladen und manuell in das `import`-Verzeichnis des
Datastores kopieren. Für `local` ist das `/var/lib/vz/import/`:

```bash
scp rhel-9.8-x86_64-kvm.qcow2 root@pve01:/var/lib/vz/import/
```

Der Datastore braucht dafür den Content-Type **Import** (Proxmox VE 8.3 oder
neuer). In `terraform.tfvars` wird das Image über `image_file_id`
referenziert, z. B. `local:import/rhel-9.8-x86_64-kvm.qcow2`.

### 3. terraform.tfvars anlegen

```bash
cd terraform/03_rhel_vm
cp terraform.tfvars.example terraform.tfvars
```

Die Werte in `terraform.tfvars` ausfüllen, insbesondere:

- `pve_endpoint`, `pve_api_token`, `node_name`
- `image_file_id` aus Schritt 2
- `ansible_ssh_public_key` (Inhalt der `.pub`-Datei)
- `ansible_password_hash`, erzeugt mit `openssl passwd -6`
- Red Hat Subscription: `rhsm_org_id` und `rhsm_activation_key`, alternativ
  `rhsm_username` und `rhsm_password`

`terraform.tfvars` ist per `.gitignore` vom Repo ausgeschlossen.

### 4. VM anlegen

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

Nach `apply` zeigt der Output `ipv4_addresses` die vom Guest-Agent gemeldete
IP. Der Login erfolgt per Key als `ansible`, `sudo` verlangt das Passwort.

## Ansible

Das Inventory liegt nicht im Repo. Zuerst die Beispieldatei kopieren und Hosts
sowie IPs anpassen:

```bash
cd ansible
cp inventories/homelab.yml.example inventories/homelab.yml
```

`ansible.cfg` setzt `remote_user = ansible`. SSH nutzt den Standard-Key bzw.
den `ssh-agent`, ein anderer Key lässt sich mit `--private-key` angeben.

```bash
ansible-playbook playbooks/patch-debian.yml
ansible-playbook playbooks/patch-rhel.yml -K
```

`-K` fragt das sudo-Passwort ab. Das ist für die RHEL-Hosts aus `03_rhel_vm`
nötig, weil dort kein `NOPASSWD`-sudo eingerichtet ist.
