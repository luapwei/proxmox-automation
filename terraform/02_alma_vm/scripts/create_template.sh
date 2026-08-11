#!/usr/bin/env bash
#
# Erstellt einmalig ein AlmaLinux-9-Cloud-Init-Template in Proxmox.
# Direkt AUF DEM PROXMOX-HOST ausfuehren (benoetigt `qm`, `wget`).
#
# Danach kann Terraform aus diesem Template klonen:
#   terraform apply
#
set -euo pipefail

# --- Konfiguration (muss zu variables.tf passen) ---
TEMPLATE_VMID="${TEMPLATE_VMID:-9000}"
TEMPLATE_NAME="${TEMPLATE_NAME:-almalinux-9-cloud}"
STORAGE="${STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
IMAGE_URL="${IMAGE_URL:-https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2}"
IMAGE_FILE="/tmp/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
# ----------------------------------------------------

if qm status "${TEMPLATE_VMID}" >/dev/null 2>&1; then
  echo "VMID ${TEMPLATE_VMID} existiert bereits. Abbruch, um nichts zu ueberschreiben."
  echo "Vorhandenes Template loeschen mit: qm destroy ${TEMPLATE_VMID}"
  exit 1
fi

echo ">> Lade AlmaLinux-9-Cloud-Image herunter..."
wget -O "${IMAGE_FILE}" "${IMAGE_URL}"

echo ">> Erstelle VM ${TEMPLATE_VMID} (${TEMPLATE_NAME})..."
qm create "${TEMPLATE_VMID}" \
  --name "${TEMPLATE_NAME}" \
  --memory 2048 \
  --cores 2 \
  --net0 "virtio,bridge=${BRIDGE}" \
  --scsihw virtio-scsi-single \
  --ostype l26 \
  --agent enabled=1

echo ">> Importiere Disk-Image nach ${STORAGE}..."
qm importdisk "${TEMPLATE_VMID}" "${IMAGE_FILE}" "${STORAGE}"

echo ">> Haenge Disk als scsi0 an..."
qm set "${TEMPLATE_VMID}" --scsi0 "${STORAGE}:vm-${TEMPLATE_VMID}-disk-0"

echo ">> Fuege Cloud-Init-Laufwerk und Boot-Reihenfolge hinzu..."
qm set "${TEMPLATE_VMID}" --ide2 "${STORAGE}:cloudinit"
qm set "${TEMPLATE_VMID}" --boot order=scsi0
qm set "${TEMPLATE_VMID}" --serial0 socket --vga serial0

echo ">> Konvertiere VM ${TEMPLATE_VMID} zu Template..."
qm template "${TEMPLATE_VMID}"

rm -f "${IMAGE_FILE}"
echo ">> Fertig. Template '${TEMPLATE_NAME}' (VMID ${TEMPLATE_VMID}) steht bereit."
