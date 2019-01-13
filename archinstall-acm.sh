# ADD HYPERVISOR SUBNET FORWARD RULES

#### BEGIN CONFIG ####

# LDAP Secrets
ACM_BINDPW=
ACM_ROOTBINDPW=


# Admin Username
ADMIN_USERNAME=acmadmin
# Admin Password
ADMIN_PASSWORD=""
# Inject Key in root account
ADMIN_KEY=""


# Install UEFI Bootloader. Specify 0 for leagacy and 1 for UEFI
INSTALL_UEFI=1
# Swapfile size in MB
SWAPSIZE=32768
# grub menu timeout
GRUB_TIMEOUT=0
# Timezone
TIMEZONE="America/Chicago"

# Hostname
HOSTNAME=chase
# Hostname from dhcp
DHCP_HOSTNAME=0
# for netctl lan profile
ETHERNET_INTERFACE=eno1
# Enable bonded interface [0/1]
ENABLE_BONDING=1
# Bonded interface name
BOND_INTERFACE=lbond0
# Interfaces to bond. Format: bash array ( first second third )
BONDED_INTERFACES='eno1 eno2 eno3 eno4'
# Primary network interface. netctl profile will be enabled and this interface will be used to route the hypervisor subnet if hypervisor install is enabled.
PRIMARY_NETWORK_INTERFACE=$BONDED_INTERFACES


# install disk /dev/sdx
DISK=/dev/sda
# is the install disk nvme?
NVME=0
# install on raid 1 (if raid is enabled, you do not need to fill out DISK and NVME)
ENABLE_RAID1=0
# list raid disks
RAID_DISKS="/dev/sda /dev/sdb"


# Install Cinnamon + LightDM [0/1]
INSTALL_GUI=0
# Install additional applications [0/1]
INSTALL_EXTRAAPPS=1
# Specify apps from the official repositories. Separate with spaces.
EXTRAAPPS="mdadm htop iotop"
# Install aurman [0/1]
INSTALL_AURMAN=1
# Install hypervisor [0/1]
INSTALL_HYPERVISOR=1
# Subnet for hypervisor 172.29.xx.0/24. Specify xx.
HYPERVISOR_SUBNET=24
# Restrict access to AcmLanAdmins and local admins
ADMIN_ONLY_ACCESS=1

#### END CONFIG ####

function partition_disk {

if [ "$ENABLE_RAID1" = "1"]
then
    # HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
    # HOOKS=(base udev autodetect modconf block mdadm_udev filesystems fsck)

    # BINARIES=()
    # BINARIES=(mdmon)
    pacman -Sy mdadm --needed --noconfirm
    # GRUB_PRELOAD_MODULES="part_gpt part_msdos"
    # GRUB_PRELOAD_MODULES="part_gpt part_msdos mdraid09 mdraid1x"
fi

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

function base_install {

sed -i '1s/^/Server = http:\/\/mozart.acm.cs\/mirror\/archlinux\/$repo\/os\/$arch \n/' /etc/pacman.d/mirrorlist
pacman -Syy

timedatectl set-ntp true

pacstrap /mnt base base-devel grub os-prober $BOOTLOADER_UEFI_PACKAGES ntfs-3g exfat-utils git vim tmux wget curl nfs-utils openssh intel-ucode bash-completion nss-pam-ldapd krb5 pam-krb5

genfstab -U /mnt >> /mnt/etc/fstab

dd if=/dev/zero of=/mnt/swapfile bs=1M count=$SWAPSIZE
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

}

function write_chroot_file {

cat << EOF > /mnt/setup.sh

function install_apps {
if [ "$INSTALL_AURMAN" = "1" ]
then
cat << EOB > /tmp/aurman.sh
cd ~
mkdir -p /tmp/aurman_install
cd /tmp/aurman_install
sudo pacman -Sy binutils make gcc fakeroot pkg-config git python python-feedparser python-dateutil python-regex python-requests pyalpm --noconfirm --needed
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=expac-git
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=aurman
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
rm -rf aurman_install
EOB
( su - $ADMIN_USERNAME -c "bash /tmp/aurman.sh" )
rm -r /tmp/aurman.sh

fi
if [ "$INSTALL_GUI" = "1" ]
then
pacman -Sy xorg cinnamon lightdm lightdm-gtk-greeter --noconfirm --needed
cat << EOM > /etc/lightdm/lightdm.conf
[LightDM]
run-directory=/run/lightdm
[Seat:*]
greeter-session=lightdm-gtk-greeter
greeter-hide-users=true
greeter-show-manual-login=true
session-wrapper=/etc/lightdm/Xsession
[XDMCPServer]
[VNCServer]
EOM
systemctl enable lightdm
fi
if [ "$INSTALL_EXTRAAPPS" = "1" ]
then
pacman -Sy $EXTRAAPPS --noconfirm --needed
fi
}

function install_hypervisor {
pacman -Sy qemu virt-manager virt-viewer dnsmasq iptables vde2 bridge-utils openbsd-netcat iptables ebtables dhcp openssl dmidecode --noconfirm --needed

cat << EOM > /root/acm_virt.xml
<network>
<name>acm_virt</name>
<forward dev='$PRIMARY_NETWORK_INTERFACE' mode='route'>
<interface dev='$PRIMARY_NETWORK_INTERFACE'/>
</forward>
<bridge name='virbr1' stp='on' delay='0'/>
<domain name='acm_virt'/>
<ip address='172.29.$HYPERVISOR_SUBNET.1' netmask='255.255.255.0'>
</ip>
</network>
EOM

systemctl enable libvirtd.service

cat << EOM > /etc/dhcpd.conf
option domain-name "acm.cs";
option domain-search "acm.cs";
option domain-name-servers ad1.acm.cs, ad2.acm.cs, ad3.acm.cs, 8.8.8.8, 8.8.4.4;
option ntp-servers mozart.acm.cs, dsk7.acm.cs;

default-lease-time 600;
max-lease-time 7200;

authoritative;

log-facility local7;

subnet 172.29.$HYPERVISOR_SUBNET.0 netmask 255.255.255.0 {
default-lease-time 21600;
max-lease-time 21600;
use-host-decl-names on;
option routers 172.29.$HYPERVISOR_SUBNET.1;
option broadcast-address 172.29.$HYPERVISOR_SUBNET.255;

pool {
range 172.29.$HYPERVISOR_SUBNET.4 172.29.$HYPERVISOR_SUBNET.200;
allow known-clients;
ignore unknown-clients;
}
}
EOM

cat << EOM > /etc/iptables/iptables.rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o virbr1 -j MASQUERADE
-A POSTROUTING -o $PRIMARY_NETWORK_INTERFACE -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A FORWARD -d 172.29.$HYPERVISOR_SUBNET.0/24 -i virbr1 -o $PRIMARY_NETWORK_INTERFACE -j ACCEPT
-A FORWARD -s 172.29.$HYPERVISOR_SUBNET.0/24 -i $PRIMARY_NETWORK_INTERFACE -o virbr1 -j ACCEPT
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

COMMIT
EOM

cat << EOM > /tmp/trousers.sh

cd /tmp
git clone https://aur.archlinux.org/trousers.git
cd trousers
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
cd ..
rm -rf trousers

EOM
( su - $ADMIN_USERNAME -c "bash /tmp/trousers.sh" )
rm -r /tmp/trousers.sh

cat << EOM > /root/hypervisor_setup_helper.sh
sleep 30

virsh net-define /root/acm_virt.xml
virsh net-start acm_virt
virsh net-autostart acm_virt

sleep 5

systemctl enable dhcpd4.service
systemctl start dhcpd4.service
rm /root/acm_virt.xml
iptables-restore /etc/iptables/iptables.rules
systemctl disable arch-install-hypervisor.service
rm /usr/lib/systemd/system/arch-install-hypervisor.service

systemctl daemon-reload
rm /root/hypervisor_setup_helper.sh

wall "Hypervisor setup helper completed"
EOM

cat << EOM > /usr/lib/systemd/system/arch-install-hypervisor.service
[Unit]
Description=Service to define libvirt networks after hypervisor install.
After=network.target libvirtd.service

[Service]
Type=simple
ExecStart=/usr/bin/env bash "/root/hypervisor_setup_helper.sh"

[Install]
WantedBy=multi-user.target
EOM

systemctl enable arch-install-hypervisor.service

cat << EOM > /etc/polkit-1/rules.d/50-libvirt.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("AcmLanAdmins")) {
            return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("$ADMIN_USERNAME")) {
            return polkit.Result.YES;
    }
});
EOM

}

function system_config {

echo "/swapfile       	none      	swap      	defaults,pri=-2	0 0" >> /etc/fstab

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

sed -i '1s/^/en_US.UTF-8 UTF-8\n/' /etc/locale.gen

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
Server = http://mozart.acm.cs/acm-packages/archlinux/
EOM

if [ "$DHCP_HOSTNAME" = "1" ]
then
echo "env force_hostname=YES" >> /etc/dhcpcd.conf
fi

cat << EOM > /etc/netctl/lan
Interface=$ETHERNET_INTERFACE
Connection=ethernet
IP=dhcp
EOM

if [ "$ENABLE_BONDING" = "1" ]
then

cat << EOM > /etc/netctl/lan-bond
Interface=$BOND_INTERFACE
Connection=bond
BindsToInterfaces=($BONDED_INTERFACES)
IP=dhcp
EOM
netctl enable lan-bond

else
netctl enable lan
fi


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

function install_bootloader {

sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=$GRUB_TIMEOUT/g' /etc/default/grub
if [ "$INSTALL_UEFI" = "1" ]
then
grub-install --recheck
else
grub-install $DISK --recheck
fi
grub-mkconfig -o /boot/grub/grub.cfg
}


function config_active_directory {

cat << EOM > /etc/krb5.conf
[libdefaults]
default_realm = ACM.CS
dns_lookup_realm = false
dns_lookup_kdc = true

[realms]

[domain_realm]
acm.cs = ACM.CS
.acm.cs = ACM.CS

[logging]
#       kdc = CONSOLE
EOM

cat << EOM > /etc/nslcd.conf

uri ldaps://ad3.acm.cs/
uri ldaps://ad2.acm.cs/
uri ldaps://ad1.acm.cs/

ldap_version 3

base dc=acm,dc=cs

binddn apacheacm@acm.cs

bindpw $ACM_BINDPW

rootpwmoddn CN=ACM PWAdmin,OU=ACMUsers,DC=acm,DC=cs

rootpwmodpw $ACM_ROOTBINDPW 

base   group  ou=ACMGroups,dc=acm,dc=cs
base   passwd ou=ACMUsers,dc=acm,dc=cs
base   shadow ou=ACMUsers,dc=acm,dc=cs

bind_timelimit 3

timelimit 30

ssl on
tls_reqcert never

pagesize 1000
referrals off
idle_timelimit 800
filter passwd (&(objectClass=user)(!(objectClass=computer))(uidNumber=*)(unixHomeDirectory=*)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))
map    passwd uid              sAMAccountName
map    passwd homeDirectory    unixHomeDirectory
map    passwd gecos            displayName
filter shadow (&(objectClass=user)(!(objectClass=computer))(uidNumber=*)(unixHomeDirectory=*)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))
map    shadow uid              sAMAccountName
map    shadow shadowLastChange pwdLastSet
filter group  (objectClass=group)

EOM

chmod 600 /etc/nslcd.conf

cat << EOM > /etc/nsswitch.conf
passwd: files ldap [NOTFOUND=return]
shadow: files ldap [NOTFOUND=return]
group: files ldap [NOTFOUND=return]

publickey: files

hosts: files mymachines myhostname resolve [!UNAVAIL=return] dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

netgroup: files
EOM

cat << EOM > /etc/pam.d/system-auth
#%PAM-1.0

auth      sufficient pam_ldap.so
auth      required  pam_unix.so     try_first_pass nullok
auth      optional  pam_permit.so
auth      required  pam_env.so
auth	  required	pam_access.so

account   sufficient pam_ldap.so
account   required  pam_unix.so
account   optional  pam_permit.so
account   required  pam_time.so

password  sufficient pam_ldap.so
password  required  pam_unix.so     try_first_pass nullok sha512 shadow
password  optional  pam_permit.so

session   required  pam_limits.so
session   required  pam_unix.so
session   required  pam_mkhomedir.so skel=/etc/skel/
session   optional  pam_ldap.so
session   optional  pam_permit.so
EOM

systemctl enable nslcd

if [ "$ADMIN_ONLY_ACCESS" = "1" ]
then

cat << EOM > /etc/security/access.conf
+:root:ALL
+:acmadmin:ALL
+:(AcmLanAdmins):ALL
-:ALL:ALL

EOM
fi
}

function config_sudoers {
rm /etc/sudoers.d/tempSudo

cat << EOM > /etc/sudoers.d/AcmAdmins
$ADMIN_USERNAME ALL=(ALL) ALL
%AcmLanAdmins ALL=(ALL) ALL
EOM
}
system_config
install_bootloader
install_apps
config_active_directory

if [ "$INSTALL_HYPERVISOR" = "1" ]
then
install_hypervisor
fi
config_sudoers


EOF

}

partition_disk
base_install
write_chroot_file

chmod +x /mnt/setup.sh

arch-chroot /mnt ./setup.sh

rm -f /mnt/setup.sh
umount -R /mnt
sync
sleep 3
reboot
