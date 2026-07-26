#!/bin/bash

echo "=========================================="
echo " Bobcat 300 Gateway Information"
echo "=========================================="
echo

CONFIG="/opt/bobcat-ttn/Bobcat300-DebianMinimalDocker/packet_forwarder/configs/global_conf.json"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found."
    echo "Did you run the installation script?"
    exit 1
fi

GWID=$(grep -oP '"gateway_ID": "\K[^"]+' "$CONFIG")
SERVER=$(grep -oP '"server_address": "\K[^"]+' "$CONFIG")

if [ -z "$GWID" ] || [ -z "$SERVER" ]; then
    echo "ERROR: Failed to read gateway configuration."
    exit 1
fi

echo "Gateway EUI : $GWID"
echo "TTN Server  : $SERVER"
echo
echo "=========================================="
echo