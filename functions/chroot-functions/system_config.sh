function system_config {

echo "/swapfile       	none      	swap      	defaults,pri=-2	0 0" >> /etc/fstab

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo LANG=$LOCALE > /etc/locale.conf
export LANG=$LOCALE

sed -i '1s/^/$LOCALE\n/' /etc/locale.gen

locale-gen

echo "$HOSTNAME" > /etc/hostname

cat << EOM > /etc/hosts
127.0.0.1      localhost
::1            localhost
EOM

cat << EOM > /etc/sudoers.d/tempSudo
$ADMIN_USERNAME ALL=(ALL) NOPASSWD:ALL
EOM

cat << EOM >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

[uicacm]
SigLevel = Optional TrustAll
Server = http://bharat.acm.cs/acm-packages/archlinux/
EOM

echo "X11Forwarding yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

systemctl enable sshd

useradd -m -d /opt/$ADMIN_USERNAME $ADMIN_USERNAME
echo "$ADMIN_USERNAME:$ADMIN_PASSWORD" | chpasswd
mkdir /root/.ssh
echo $ADMIN_KEY >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

passwd -l root

}
