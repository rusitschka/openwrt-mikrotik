#!/bin/bash -e

# based on https://openwrt.org/toh/mikrotik/common

if [ -z "$1" ] || [ -z "$2" ]
then
  echo "Missing parameter(s)!"
  echo "Call with $0 <interface> <sysupgrade file path>"
  exit 1
fi

IFNAME="$1"
TFTP_ROOT=$(dirname $2)
TFTP_FILE=$(basename $2)

echo
echo "You've selected interface $IFNAME. This interface has to manually"
echo "be configured to have IP address 192.168.1.10!"
echo
echo -n "Press [ENTER] to continue... "
read

set -x

USER=$(whoami)

sudo dnsmasq --user=$USER \
    --no-daemon \
    --listen-address 192.168.1.10 \
    --bind-interfaces \
    -p0 \
    --dhcp-authoritative \
    --dhcp-range=192.168.1.100,192.168.1.200 \
    --bootp-dynamic \
    --dhcp-boot="$TFTP_FILE" \
    --log-dhcp \
    --enable-tftp \
    --tftp-root="$TFTP_ROOT"
