# Function to partition install disk

function partition_disk {

# If the drive is nvme, add 'p' after the drive name.
# nvme drives have a slightly difffrent naming scheme in linux.
NVME_PART=''
if [ "$NVME" = "1" ]
then
    NVME_PART='p'
fi

if [ "$INSTALL_UEFI" = "1" ]
then

# Partition disk with gpt for uefi
fdisk $DISK <<EOM
g
n


+500M
n



w
EOM

# Format and mount patitions
mkfs.fat -F 32 $DISK$NVME_PART'1'
mkfs.ext4 $DISK$NVME_PART'2'
mount $DISK$NVME_PART'2' /mnt
mkdir -p /mnt/boot/efi
mount $DISK$NVME_PART'1' /mnt/boot/efi

BOOTLOADER_UEFI_PACKAGES="efibootmgr dosfstools"
else
# Partition disk with mbr for legacy/bios
fdisk $DISK <<EOM
o
n




w
EOM

# Format and mount partitions
mkfs.ext4 $DISK'1'
mount $DISK'1' /mnt
fi
}
