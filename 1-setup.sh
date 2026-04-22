#!/bin/sh

# Mounts sandbox/ as a tmpfs; minimizes SSD teardown for 2-test.sh.
# (This is completely optional.)

mkdir -p sandbox
sudo mount -o size=512M -t tmpfs none sandbox


# Required for routers-connectivity/frr testing (optional)
#sudo /usr/lib/frr/frrinit.sh start


# Required for routers-connectivity/cisco testing (optional)
#sudo ip link add br-lab type bridge
#sudo ip addr add 10.0.0.1/24 dev br-lab
#sudo ip link set br-lab up
#sudo mkdir -p /etc/qemu
#echo "allow br-lab" | sudo tee -a /etc/qemu/bridge.conf > /dev/null
#sudo chmod 644 /etc/qemu/bridge.conf
#HELPER_PATH="/usr/lib/qemu/qemu-bridge-helper" 
#sudo chmod u+s $HELPER_PATH
#sudo ufw allow in on br-lab to any port 8323 proto tcp