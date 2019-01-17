#!/bin/bash

# Import configs and functions
source /root/master.env
source ./functions/*.sh
declare > /test
exit

# Wipe and Install
partition_disk
base_install

# Configure System
write_chroot_file
chmod +x /mnt/setup.sh
arch-chroot /mnt ./setup.sh

# Cleanup
rm /root/master.env
rm -r /root/functions
rm /mnt/setup.sh

# Unmount
umount -R /mnt
sync

# Reboot
sleep 3
reboot
