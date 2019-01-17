#!/bin/bash

SECRETS='config/secrets.env'
GLOBAL='config/global.env'


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

export $SECRETS
export $GLOBAL_CONFIG
export $CONFIG_FILE

ssh root@$SSH_HOST < archinstall-acm.sh
