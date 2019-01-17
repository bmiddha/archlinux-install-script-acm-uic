function network_config {
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
}
