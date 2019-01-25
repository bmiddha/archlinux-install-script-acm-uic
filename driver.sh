#!/bin/bash

# Global and secret configs
SECRETS='configs/secrets.env'
GLOBAL='configs/global.env'

# Print script usage
function usage {
    echo "Usage: $0 --profile <profile> --host <ip/hostname>"
    echo "      -p, --profile           specify profile file"
    echo "      -h, --host              specify host"
    echo "      -k, --key               ssh key file"
    echo "      --help                  Displays Help Information"
    echo "Example: $0 --config config/virtual-machine.env --host computer.example.com"
}

# Check is no arguements are supplied
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    usage
    exit
fi

# Read options/flags
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--profile)
    PROFILE="$2"
    shift
    shift
    ;;
    -h|--host)
    SSH_HOST="$2"
    shift
    shift
    ;;
    -k|--key)
    SSH_KEY="$2"
    shift
    shift
    ;;
    --help)
    usage
    exit
    shift
    ;;
    *)
    usage
    exit
    shift
    ;;
esac
done

# Write master config file
echo "" > master.env
cat $SECRETS >> master.env
echo "" >> master.env
cat $GLOBAL >> master.env
echo "" >> master.env
cat $PROFILE >> master.env
echo "" >> master.env

echo > master.sh
cat functions/*.sh  >> master.sh


echo "Transferring config files to remote host"
# Transfer master config and functions to remote host
scp -r master.env master.sh functions/chroot-functions root@$SSH_HOST:/root/
# scp -r functions root@$SSH_HOST:/root/

echo "Running script on remote host"
# Run install script on remote host
ssh root@$SSH_HOST -i "$SSH_KEY" < archinstall-acm.sh

# Remove master.env
rm master.env master.sh

echo -e "\n\n\nScript Ended\n\n\n"
exit
