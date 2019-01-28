# Function to install and configre libvirtd
function install_hypervisor {

# Exit function if INSTALL_HYPERVISOR is not set to 1
if [ "$INSTALL_HYPERVISOR" -ne "1" ]
then
    return
fi

# Install dependencies and the hypervisor
pacman -Sy qemu dnsmasq libvirt iptables vde2 bridge-utils openbsd-netcat iptables ebtables dhcp openssl dmidecode ovmf --noconfirm --needed

# Configure virual network
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

# Configure UEFI on QEMU
cat << EOM >> /etc/libvirt/qemu.conf
nvram = [
    "/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
]
EOM

# Configure DHCP Servere for the virtual Network
cat << EOM > /etc/dhcpd.conf
option domain-name "acm.cs";
option domain-search "acm.cs";
option domain-name-servers ad1.acm.cs, ad2.acm.cs, ad3.acm.cs, 8.8.8.8, 8.8.4.4;
option ntp-servers bharat.acm.cs, lee.acm.cs;

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

# Configure routing tables to route traffic between the virtual and physical network
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

# Temporary sudo file to install trousers from AUR
cat << EOM > /etc/sudoers.d/tempSudo
$ADMIN_USERNAME ALL=(ALL) NOPASSWD:ALL
EOM

# Install Trousers for TPM support and virtio drivers for windows guests
cat << EOM > /tmp/hypervisor-aur.sh

cd /tmp
git clone https://aur.archlinux.org/trousers.git
cd trousers
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
cd ..
git clone https://aur.archlinux.org/virtio-win.git
cd virtio-win
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
cd ..

EOM

# Start virtual network and dhcp server on next boot
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

# Oneshot service to run the helper script
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

# Polkit rules to allow admins to access libvirt
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

# Enalbel Libvirt Service
systemctl enable libvirtd.service
# Run trousers install script
( su - $ADMIN_USERNAME -c "bash /tmp/hypervisor-aur.sh" )
# Delete trouser srource and install script
rm -r /tmp/hypervisor-aur.sh /tmp/hypervisor-aur
# Remove temporary sudo acccess
rm /etc/sudoers.d/tempSudo
# Enable the oneshot helper scirpt service
systemctl enable arch-install-hypervisor.service

}
