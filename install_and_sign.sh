#!/bin/bash
set -e

# Change to the root directory of the driver repository
cd /home/joseph/aic8800d80/drivers/aic8800

# Install the modules
echo "Installing the compiled driver modules..."
make install

# Check if Secure Boot is enabled, and sign the modules if true
if mokutil --sb-state | grep -q "SecureBoot enabled"; then
    echo "Secure Boot is enabled. Searching for MOK keys..."
    
    # Path to Ubuntu's default auto-generated MOK 
    MOK_PRIV="/var/lib/shim-signed/mok/MOK.priv"
    MOK_DER="/var/lib/shim-signed/mok/MOK.der"
    
    if [ -f "$MOK_PRIV" ] && [ -f "$MOK_DER" ]; then
        echo "Found default MOK keys. Signing modules..."
        /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 \
            $MOK_PRIV $MOK_DER /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/aic_load_fw.ko
            
        /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 \
            $MOK_PRIV $MOK_DER /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/aic8800_fdrv.ko
            
        echo "Modules signed successfully."
    else
        echo "Error: Could not find MOK keys in /var/lib/shim-signed/mok/. You may need to manually sign them or create a new key."
        exit 1
    fi
fi

# Reload the module dependencies
depmod -a

# Load the new modules
echo "Loading the compiled modules..."
modprobe aic8800_fdrv

echo "Driver installed and loaded successfully. Your Wi-Fi adapter should now switch from a disk drive to its normal wireless mode."
