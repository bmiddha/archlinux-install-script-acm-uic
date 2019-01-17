#!/bin/bash

SECRETS='configs/secrets.env'
GLOBAL='configs/global.env'

function usage {
    echo "Usage: $0 --config <config> --host <ip/hostname>"
    echo "      -c, --config            specify config file"
    echo "      -h, --host              specify host"
    echo "      --help                  Displays Help Information"
    echo "Example: $0 --config config/virtual-machine.env --host computer.example.com"
}


if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    usage
    exit
fi


while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--config)
    CONFIG_FILE="$2"
    shift
    shift
    ;;
    -h|--host)
    SSH_HOST="$2"
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

echo "" > master.env
cat $SECRETS >> master.env
echo 1
cat $GLOBAL >> master.env
echo 2
cat $CONFIG_FILE >> master.env
echo 3

scp master.env root@$SSH_HOST:/root/
scp -r functions root@$SSH_HOST:/root/
ssh root@$SSH_HOST < archinstall-acm.sh

rm master.env
echo -e "\n\n\nScript Ended\n\n\n"

exit
