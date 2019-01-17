function write_chroot_file {

echo "" > /mnt/setup.sh

cat chroot-functions/*.sh >> /mnt/setup.sh

cat << EOF >> /mnt/setup.sh

system_config
network_config
install_bootloader
install_apps

if [ "$CONFIGURE_ACTIVE_DIRECTORY" = "1" ]
then
config_active_directory
fi

if [ "$INSTALL_HYPERVISOR" = "1" ]
then
install_hypervisor
fi

config_sudoers


EOF

}
