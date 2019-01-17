# Function setup a base install of archlinux
function base_install {

# Set pacman mirror
sed -i '1s/^/Server = $MIRROR \n/' /etc/pacman.d/mirrorlist

# Update package list
pacman -Syy

# Set time from ntp
timedatectl set-ntp true

# Install archlinux
pacstrap /mnt base base-devel grub os-prober $BOOTLOADER_UEFI_PACKAGES ntfs-3g exfat-utils git vim tmux wget curl nfs-utils openssh intel-ucode bash-completion nss-pam-ldapd krb5 pam-krb5

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Generate swapfile
dd if=/dev/zero of=/mnt/swapfile bs=1M count=$SWAPSIZE
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

}
