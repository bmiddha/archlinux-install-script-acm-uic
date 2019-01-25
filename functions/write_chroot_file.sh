# Function to write the setup script which will run in chroot.
function write_chroot_file {

# Overwrite old setup file (if exists)
echo "" > /mnt/setup.sh

# Append all chroot functions and variables
cat master.env >> /mnt/setup.sh
cat chroot-functions/*.sh >> /mnt/setup.sh

# Run chroot-functions
cat << EOF >> /mnt/setup.sh

system_config
network_config
install_bootloader
install_apps
config_active_directory
install_hypervisor
config_sudoers


EOF

}
