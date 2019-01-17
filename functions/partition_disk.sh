function partition_disk {

NVME_PART=''
if [ "$NVME" = "1" ]
then
    NVME_PART='p'
fi

if [ "$INSTALL_UEFI" = "1" ]
then

fdisk $DISK <<EOM
g
n


+500M
n



w
EOM

mkfs.fat -F 32 $DISK$NVME_PART'1'
mkfs.ext4 $DISK$NVME_PART'2'
mount $DISK$NVME_PART'2' /mnt
mkdir -p /mnt/boot/efi
mount $DISK$NVME_PART'1' /mnt/boot/efi

BOOTLOADER_UEFI_PACKAGES="efibootmgr dosfstools"
else
fdisk $DISK <<EOM
o
n




w
EOM

mkfs.ext4 $DISK'1'
mount $DISK'1' /mnt
fi
}
