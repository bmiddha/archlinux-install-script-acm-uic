# Function to install and congufure GRUB
function install_bootloader {

sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=$GRUB_TIMEOUT/g' /etc/default/grub
# Check if INSTALL_UEFI is set to 1
if [ "$INSTALL_UEFI" = "1" ]
then
grub-install --recheck
else
grub-install $DISK --recheck
fi
grub-mkconfig -o /boot/grub/grub.cfg
}
