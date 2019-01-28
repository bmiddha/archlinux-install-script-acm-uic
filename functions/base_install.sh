# Function setup a base install of archlinux
function base_install {

# Set pacman mirror
echo -e "Server = $MIRROR\nServer = $MIRROR2" | cat - /etc/pacman.d/mirrorlist > temp && mv temp /etc/pacman.d/mirrorlist
# Update package list
pacman -Syy

# Set time from ntp
timedatectl set-ntp true

# Install archlinux
pacstrap /mnt base base-devel grub os-prober $BOOTLOADER_UEFI_PACKAGES ntfs-3g exfat-utils git vim tmux wget curl nfs-utils openssh intel-ucode bash-completion

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Generate swapfile
dd if=/dev/zero of=/mnt/swapfile bs=1M count=$SWAPSIZE
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

}
