# Function to configre netctl and bonding
function network_config {

# Get hostname from dhcp
if [ "$DHCP_HOSTNAME" = "1" ]
then
echo "env force_hostname=YES" >> /etc/dhcpcd.conf
fi

# Confiure lan netctl profile
cat << EOM > /etc/netctl/lan
Interface=$ETHERNET_INTERFACE
Connection=ethernet
IP=dhcp
EOM

# Configure bonding netctl profile
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
