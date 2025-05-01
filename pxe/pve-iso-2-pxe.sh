#!/bin/bash

# Add logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a pve-iso-2-pxe.log
}

cat << EOF

#########################################################################################################
# Create PXE bootable Proxmox image including ISO                                                       #
#                                                                                                       #
# Author: mrballcb @ Proxmox Forum (06-12-2012)                                                         #
# Thread: http://forum.proxmox.com/threads/8484-Proxmox-installation-via-PXE-solution?p=55985#post55985 #
# Modified: morph027 @ Proxmox Forum (23-02-2015) to work with 3.4                                      #
#########################################################################################################

EOF

if [ ! $# -eq 1 ]; then
  log_message "Error: Missing ISO path argument"
  echo -ne "Usage: bash pve-iso-2-pxe.sh /path/to/pve.iso\n\n"
  exit 1
fi

log_message "Starting PVE ISO to PXE conversion"
log_message "Working with ISO: $1"

BASEDIR="$(dirname "$(readlink -f "$1")")"
log_message "Base directory: $BASEDIR"
pushd "$BASEDIR" >/dev/null || { log_message "Error: Cannot change to base directory"; exit 1; }

[ -L "proxmox.iso" ] && { log_message "Removing existing proxmox.iso symlink"; rm proxmox.iso &>/dev/null; }

for ISO in *.iso; do
  if [ "$ISO" = "*.iso" ]; then log_message "No ISO files found in directory"; continue; fi
  if [ "$ISO" = "proxmox.iso" ]; then continue; fi
  log_message "Using ${ISO}..."
  ln -s "$ISO" proxmox.iso
done

if [ ! -f "proxmox.iso" ]; then
  log_message "Error: Couldn't find a proxmox iso"
  echo "Couldn't find a proxmox iso, aborting."
  echo "Add /path/to/iso_dir to the commandline."
  exit 2
fi

log_message "Checking for required tools..."
for tool in isoinfo 7z file cpio; do
    if command -v $tool >/dev/null 2>&1; then
        log_message "$tool: Found"
    else
        log_message "Warning: $tool not found"
    fi
done

rm -rf pxeboot
[ -d pxeboot ] || { mkdir pxeboot || { log_message "Error: Cannot create pxeboot directory"; exit 1; }; }

pushd pxeboot >/dev/null || { log_message "Error: Cannot change to pxeboot directory"; exit 1; }
log_message "Extracting kernel..."
if [ -x $(which isoinfo) ] ; then
  isoinfo -i ../proxmox.iso -R -x /boot/linux26 > linux26 || { log_message "Error: Kernel extraction failed with isoinfo"; exit 3; }
else
  7z x ../proxmox.iso boot/linux26 -o/tmp || { log_message "Error: Kernel extraction failed with 7z"; exit 3; }
  mv /tmp/boot/linux26 /tmp/
fi

log_message "Extracting initrd..."
if [ -x $(which isoinfo) ] ; then
  isoinfo -i ../proxmox.iso -R -x /boot/initrd.img > /tmp/initrd.img
else
  7z x ../proxmox.iso boot/initrd.img -o/tmp
  mv /tmp/boot/initrd.img /tmp/
fi

log_message "Detecting initrd compression method..."
mimetype="$(file --mime-type --brief /tmp/initrd.img)"
log_message "Detected mimetype: $mimetype"

case "${mimetype##*/}" in
  "zstd"|"x-zstd")
    log_message "Using zstd decompression"
    decompress="zstd -d /tmp/initrd.img -c"
    ;;
  "gzip"|"x-gzip")
    log_message "Using gzip decompression"
    decompress="gzip -S img -d /tmp/initrd.img -c"
    ;;
  *)
    log_message "Error: Unable to detect initrd compression method"
    echo "unable to detect initrd compression method, exiting"
    exit 1
    ;;
esac

$decompress > initrd || { log_message "Error: Decompression failed"; exit 4; }
log_message "Adding iso file to initrd..."
if [ -x $(which cpio) ] ; then
  echo "../proxmox.iso" | cpio -L -H newc -o >> initrd || { log_message "Error: Failed to add ISO with cpio"; exit 5; }
else
  7z x "../proxmox.iso" >> initrd || { log_message "Error: Failed to add ISO with 7z"; exit 5; }
fi
popd >/dev/null 2>&1 || { log_message "Error: Cannot return from pxeboot directory"; exit 1; }

log_message "Process completed successfully"
log_message "PXE boot files can be found in ${PWD}/pxeboot"
popd >/dev/null 2>&1 || true  # don't care if these pops fail
popd >/dev/null 2>&1 || true
