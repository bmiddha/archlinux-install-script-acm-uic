function config_active_directory {

# Exit function if CONFIGURE_ACTIVE_DIRECTORY is not set to 1
if [ "$CONFIGURE_ACTIVE_DIRECTORY" -ne "1" ]
then
    return
fi

pacman -Sy nss-pam-ldapd krb5 pam-krb5 --noconfirm --needed

# Configure kerbros
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

# Configure nslcd
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
# Set permissions on nslcd.cong
chmod 600 /etc/nslcd.conf

# Configure nsswitch
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

# Configure pam to auto-create home directories, use ldap to login, and use access.conf to regulate login access
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

# Enable nslcd service
systemctl enable nslcd

# Configure admin only access
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
