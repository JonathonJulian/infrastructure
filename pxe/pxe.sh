#!/bin/bash

# Configuration
VM_NAME="pxe-server"
VM_CPU=2
VM_MEM=2G
VM_DISK=10G
ISO_FILE="proxmox-ve_8.1-1.iso"
ISO_URL="https://mirrors.gigenet.com/proxmox/iso/proxmox-ve_8.1-1.iso"
LOG_FILE="pxe_setup.log"

# Create log file
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting PXE server setup..."

# Check if ISO exists and is valid
if [ -f "$ISO_FILE" ]; then
    echo "Checking existing ISO file..."
    echo "File size: $(du -h "$ISO_FILE" | cut -f1)"
    echo "File type: $(file "$ISO_FILE")"
    if ! file "$ISO_FILE" | grep -q "ISO 9660"; then
        echo "Existing ISO file is invalid. Removing..."
        rm "$ISO_FILE"
    else
        echo "Valid ISO file found."
    fi
fi

# Check if proxmox.iso exists and is valid
if [ -f "proxmox.iso" ]; then
    echo "Found proxmox.iso file..."
    echo "File size: $(du -h proxmox.iso | cut -f1)"
    echo "File type: $(file proxmox.iso)"
    if file proxmox.iso | grep -q "ISO 9660"; then
        echo "proxmox.iso appears to be a valid ISO file"
        echo "Copying proxmox.iso to $ISO_FILE..."
        cp proxmox.iso "$ISO_FILE"
    else
        echo "proxmox.iso is not a valid ISO file"
    fi
fi

# Download ISO if needed
if [ ! -f "$ISO_FILE" ]; then
    echo "Downloading Proxmox ISO..."
    curl -k -L -o "$ISO_FILE" "$ISO_URL"

    # Verify ISO
    echo "Verifying downloaded ISO..."
    echo "File size: $(du -h "$ISO_FILE" | cut -f1)"
    echo "File type: $(file "$ISO_FILE")"
    if ! file "$ISO_FILE" | grep -q "ISO 9660"; then
        echo "Error: Downloaded file is not a valid ISO image"
        exit 1
    fi
fi

# Check if VM exists and delete if it does
if multipass list | grep -q "$VM_NAME"; then
    echo "VM $VM_NAME already exists. Deleting..."
    multipass delete "$VM_NAME" && multipass purge
fi

# Launch VM with bridged networking to en12
echo "Launching VM with bridged networking..."
multipass launch -n "$VM_NAME" -c "$VM_CPU" -m "$VM_MEM" -d "$VM_DISK" --network name=en12,mode=manual

# Wait for VM to be ready
sleep 10

# Configure VM network
echo "Configuring VM network..."
multipass exec "$VM_NAME" -- sudo bash -c '
ip link set dev enp0s1 up
ip addr add 192.168.10.1/24 dev enp0s1
'

# Get VM IP
VM_IP=$(multipass exec "$VM_NAME" -- ip -4 addr show dev enp0s1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "VM IP: $VM_IP"

# Transfer files to VM
echo "Transferring files to VM..."
multipass transfer "$ISO_FILE" "$VM_NAME:/home/ubuntu/"
multipass transfer "pve-iso-2-pxe.sh" "$VM_NAME:/home/ubuntu/"

# Execute setup script inside VM
echo "Configuring PXE server..."
multipass exec "$VM_NAME" -- sudo bash << 'EOFSCRIPT'
# Set PATH and environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# Remove any existing locks
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock*

# Update package lists
sudo apt-get update

# Install required packages
for pkg in isc-dhcp-server tftpd-hpa apache2 p7zip-full genisoimage; do
    echo "Installing $pkg..."
    if ! sudo apt-get install -y $pkg; then
        echo "Failed to install $pkg"
        exit 1
    fi
done

# Create pxeboot directory
sudo mkdir -p /home/ubuntu/pxeboot
sudo chown ubuntu:ubuntu /home/ubuntu/pxeboot

# Make script executable and run it
chmod +x pve-iso-2-pxe.sh
./pve-iso-2-pxe.sh /home/ubuntu/proxmox-ve_8.1-1.iso

# Configure TFTP server
sudo tee /etc/default/tftpd-hpa << EOF
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/home/ubuntu/pxeboot"
TFTP_ADDRESS="192.168.10.1:69"
TFTP_OPTIONS="--secure"
EOF

# Configure DHCP server
sudo tee /etc/dhcp/dhcpd.conf << EOF
subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.100 192.168.10.200;
  option routers 192.168.10.1;
  option domain-name-servers 192.168.10.1;
  next-server 192.168.10.1;
  filename "pxelinux.0";
}

class "pxeclients" {
  match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
  next-server 192.168.10.1;
  filename "pxelinux.0";
}
EOF

# Configure DHCP to listen on the correct interface
sudo tee /etc/default/isc-dhcp-server << EOF
INTERFACESv4="enp0s1"
INTERFACESv6=""
EOF

# Restart services
sudo systemctl restart tftpd-hpa
sudo systemctl restart isc-dhcp-server

# Verify services are running
echo "Checking TFTP server status:"
sudo systemctl status tftpd-hpa
echo "Checking DHCP server status:"
sudo systemctl status isc-dhcp-server
EOFSCRIPT

echo "PXE server setup complete. VM IP: $VM_IP"
echo "Check pxe_setup.log for detailed information."
