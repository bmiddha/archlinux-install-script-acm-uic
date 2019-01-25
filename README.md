# archlinux-instal-script-acm-uic

# Configure

Configure the `.env` files as needed. Configs are located in the `configs/` directory.

Copy/rename `secrets.env.example` to `secrets.env` and modify as needed. Modify `global.env` as needed.

This script comes with a few profiles:
- workstation
- hypervisor
- virtual-mahine


Boot into archiso, enable ssh server, and set the root password
```
systemctl start sshd
echo "root:superPASSWORRD" | chpasswd
```
Then run `driver.sh` from a computer on the network.

# Usage

```
Usage: driver.sh --profile <profile> --host <ip/hostname>
      -p, --profile           specify profile file
      -h, --host              specify host
      -k, --key               ssh key file
      --help                  Displays Help Information
Example: driver.sh --config config/virtual-machine.env --host computer.example.com
```
