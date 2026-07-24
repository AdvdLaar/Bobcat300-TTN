#!/bin/bash

echo "=========================================="
echo " Bobcat 300 Gateway Information"
echo "=========================================="
echo

#--------------------------------------------------
# Find config file
#--------------------------------------------------

CONFIG=$(find /opt/bobcat-ttn -name "global_conf.json" 2>/dev/null | head -n1)

if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found."
    echo "Did you run the installation script?"
    exit 1
fi

#--------------------------------------------------
# Extract Gateway EUI
#--------------------------------------------------

GWID=$(grep -oP '"gateway_ID": "\K[^"]+' "$CONFIG")

if [ -z "$GWID" ]; then
    echo "ERROR: Gateway ID not found in config."
    exit 1
fi

#--------------------------------------------------
# Extract TTN Server
#--------------------------------------------------

SERVER=$(grep -oP '"server_address": "\K[^"]+' "$CONFIG")

if [ -z "$SERVER" ]; then
    echo "ERROR: Server address not found in config."
    exit 1
fi

#--------------------------------------------------
# Display information
#--------------------------------------------------

echo "Gateway EUI:"
echo "$GWID"
echo
echo "TTN Server:"
echo "$SERVER"
echo
echo "=========================================="
echo