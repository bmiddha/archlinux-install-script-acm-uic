# archlinux-install-script-acm-uic

## Configure

Configure the `.env` files as needed. Configs are located in the `configs/` directory.

Copy/rename `secrets.env.example` to `secrets.env` and modify as needed. Modify `global.env` as needed.

This script comes with a few profiles:
- workstation
- hypervisor
- virtual-mahine


Boot into archiso, enable ssh server, and set the root password
```bash
systemctl start sshd
echo "root:superPASSWORRD" | chpasswd
```
Then run `driver.sh` from a computer on the network.

## Usage

```
Usage: driver.sh --profile <profile> --host <ip/hostname>
      -p, --profile           specify profile file
      -h, --host              specify host
      -k, --key               ssh key file
      --help                  Displays Help Information
Example: driver.sh --config config/virtual-machine.env --host computer.example.com
```



## What does it do?

Here is an outline of the workings of the script

- Inject SSH key 
- Login into remote host
- Partition, format, and mount
- Install archlinux
  - Inject local and LUG@MTU archlinux mirror
  - Update repository lists
  - Run pacstrap
  - Generate fstab
  - Generate and configure swapfile
- `chroot` into the new archlinux intsall
  - Configure system basics
    - Timezone
    - Locale and Language
    - Hostname and hosts
    - `pacman` config
    - Configure ACM pacman repository
    - Configure ssh server
    - Add users, inject keys, and lock root
  - Configure network
    - Setup bonding
    - Get hostname from DHCP
  - Configure sudoers
  - Configure ACM active directory
  - Install and configure hypervisor
    - Install qemu, libvirt
    - Configure virtual network
    - Configure iptables forwarding for virtual network
    - Configure DHCP server
    - Configure UEFI for qemu
    - Install virtio drivers for Windows guests
  - Install apps
    - Install and configure aurman
    - Optimize makepkg
    - Install extra apps from config files
  - Install Bootloader
    - Set bootloader timeout to 0
    - Install and configure GRUB
## archiso customizations
`airootfs/root/customize_airootfs.sh`
```bash
systemctl enable sshd
echo "root:superPASSWORD" | chpasswd
```
`efiboot/loader/loader.conf`
```
timeout 0
default archiso-x86_64
```
