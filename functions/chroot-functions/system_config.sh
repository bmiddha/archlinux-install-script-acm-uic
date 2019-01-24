# Function to configure basic settings.
function system_config {

# Add swapfile to fstab
echo "/swapfile       	none      	swap      	defaults,pri=-2	0 0" >> /etc/fstab

# Set timezone and locale
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo LANG=$LOCALE > /etc/locale.conf
export LANG=$LOCALE

echo -e "$LOCALE" | cat - /etc/locale.gen > temp && mv temp /etc/locale.gen

locale-gen

# Set hostname
echo "$HOSTNAME" > /etc/hostname

cat << EOM > /etc/hosts
127.0.0.1      localhost
::1            localhost
EOM

# Configure pacman
cat << EOM >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

[uicacm]
SigLevel = Optional TrustAll
Server = http://bharat.acm.cs/acm-packages/archlinux/
EOM

# Configure ssh server
echo "X11Forwarding yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

systemctl enable sshd

# Configure users
useradd -m -d /opt/$ADMIN_USERNAME $ADMIN_USERNAME
echo "$ADMIN_USERNAME:$ADMIN_PASSWORD" | chpasswd
mkdir /root/.ssh
echo $ADMIN_KEY >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

passwd -l root

}
