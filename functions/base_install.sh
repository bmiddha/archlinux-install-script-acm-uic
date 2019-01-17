function base_install {

sed -i '1s/^/Server = $MIRROR \n/' /etc/pacman.d/mirrorlist
pacman -Syy

timedatectl set-ntp true

pacstrap /mnt base base-devel grub os-prober $BOOTLOADER_UEFI_PACKAGES ntfs-3g exfat-utils git vim tmux wget curl nfs-utils openssh intel-ucode bash-completion nss-pam-ldapd krb5 pam-krb5

genfstab -U /mnt >> /mnt/etc/fstab

dd if=/dev/zero of=/mnt/swapfile bs=1M count=$SWAPSIZE
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

}
