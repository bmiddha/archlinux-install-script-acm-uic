function config_sudoers {
rm /etc/sudoers.d/tempSudo

cat << EOM > /etc/sudoers.d/AcmAdmins
$ADMIN_USERNAME ALL=(ALL) ALL
%AcmLanAdmins ALL=(ALL) ALL
EOM
}
