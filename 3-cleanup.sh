#!/bin/sh

# Reverts 1-setup.sh.

echo "[INFO] Starting environment cleanup..."

sudo umount sandbox
#sudo /usr/lib/frr/frrinit.sh stop


# 1. Revert SUID bit on QEMU bridge helper (Security best practice)
# This prevents the binary from running with root privileges after tests
#HELPER_PATH="/usr/lib/qemu/qemu-bridge-helper"
#if [ -f "$HELPER_PATH" ]; then
#    sudo chmod u-s "$HELPER_PATH"
#    echo "[OK] SUID bit removed from $HELPER_PATH"
#else
#    echo "[SKIP] Helper not found at $HELPER_PATH"
#fi

# 2. Clean up QEMU bridge configuration
# Use sed to delete only the specific line related to our lab bridge
#BRIDGE_CONF="/etc/qemu/bridge.conf"
#if [ -f "$BRIDGE_CONF" ]; then
#    sudo sed -i '/allow br-lab/d' "$BRIDGE_CONF"
#    echo "[OK] 'allow br-lab' removed from $BRIDGE_CONF"
#fi

# 3. Teardown the network bridge interface
# Removing the bridge automatically clears the 10.0.0.1 IP and routes
#if ip link show br-lab >/dev/null 2>&1; then
#    echo "[INFO] Deleting bridge interface br-lab..."
#    sudo ip link set br-lab down
#    sudo ip link delete br-lab type bridge
#    sudo ufw delete allow in on br-lab to any port 8323 proto tcp
#    echo "[OK] Network interface br-lab deleted"
#else
#    echo "[WARN] Interface br-lab does not exist, skipping"
#fi

echo "[SUCCESS] Cleanup process finished."