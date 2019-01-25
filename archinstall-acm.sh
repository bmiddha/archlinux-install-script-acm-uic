#!/bin/bash

# Import configs and functions
source /root/master.env
source /root/master.sh

# Wipe and Install
partition_disk
base_install

# Configure System
write_chroot_file
chmod +x /mnt/setup.sh
# exit
arch-chroot /mnt ./setup.sh

# Cleanup
rm /root/master.env /root/master.sh
rm /mnt/setup.sh

# Unmount
umount -R /mnt
sync

# Reboot
sleep 3
reboot
