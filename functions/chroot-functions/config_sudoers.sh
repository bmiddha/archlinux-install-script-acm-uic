# Function to give sudo access to users, and groups
function config_sudoers {

cat << EOM > /etc/sudoers.d/AcmAdmins
$ADMIN_USERNAME ALL=(ALL) ALL
%AcmLanAdmins ALL=(ALL) ALL
EOM
}
