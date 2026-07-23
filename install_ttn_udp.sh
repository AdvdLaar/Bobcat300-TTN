#!/bin/bash

set -e

echo "=========================================="
echo " Bobcat 300 G285 -> TTN UDP Gateway"
echo "=========================================="
echo

#--------------------------------------------------
# Root check
#--------------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

#--------------------------------------------------
# Find repository
#--------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$SCRIPT_DIR/Bobcat300-DebianMinimalDocker"

if [ ! -d "$REPO" ]; then
    REPO=$(find / -type d -name "Bobcat300-DebianMinimalDocker" 2>/dev/null | head -n1)
fi

if [ -z "$REPO" ] || [ ! -d "$REPO" ]; then
    echo "ERROR: Bobcat300-DebianMinimalDocker not found."
    echo "Run install_helium.sh first."
    exit 1
fi

echo "Repository:"
echo " $REPO"
echo

cd "$REPO"

#--------------------------------------------------
# Find config
#--------------------------------------------------

CONFIG=$(find "$REPO" -name "global_conf.json" | head -n1)

if [ -z "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found."
    exit 1
fi

echo "Config:"
echo " $CONFIG"
echo

#--------------------------------------------------
# Determine MAC address
#--------------------------------------------------

if [ -d /sys/class/net/end0 ]; then
    IFACE="end0"
elif [ -d /sys/class/net/eth0 ]; then
    IFACE="eth0"
elif [ -d /sys/class/net/wlan0 ]; then
    IFACE="wlan0"
else
    echo "ERROR: No network interface found."
    exit 1
fi

MAC=$(tr -d ':' < /sys/class/net/$IFACE/address | tr '[:lower:]' '[:upper:]')

if [ -z "$MAC" ]; then
    echo "ERROR: MAC address unavailable."
    exit 1
fi

GWID="${MAC:0:6}FFFE${MAC:6:6}"

echo "Interface:"
echo " $IFACE"

echo "MAC:"
echo " $MAC"

echo "Gateway EUI:"
echo " $GWID"
echo

#--------------------------------------------------
# Update TTN configuration
#--------------------------------------------------

echo "Configuring TTN..."

sed -i \
    -e "s/\"gateway_ID\": \".*\"/\"gateway_ID\": \"$GWID\"/" \
    -e 's/"server_address": ".*"/"server_address": "eu1.cloud.thethings.network"/' \
    -e 's/"serv_port_up":.*/"serv_port_up": 1700,/' \
    -e 's/"serv_port_down":.*/"serv_port_down": 1700,/' \
    "$CONFIG"

echo "TTN configuration updated."
echo

#--------------------------------------------------
# Replace compose file
#--------------------------------------------------

COMPOSE="$REPO/docker-compose-G285.yml"

if [ -f "$COMPOSE" ] && [ ! -f "$COMPOSE.bak" ]; then
    echo "Backing up original compose file..."
    cp "$COMPOSE" "$COMPOSE.bak"
fi


echo "Creating TTN-only docker-compose file..."

cat > "$COMPOSE" <<'EOF'
version: '3'

services:
  pktfwd:
    image: ghcr.io/heliumdiy/sx1302_hal:sha-87d8931
    entrypoint: ["/opt/packet_forwarder/entrypoint.sh"]
    working_dir: /opt/packet_forwarder
    environment:
      VENDOR: bobcat
      REGION: EU868
    privileged: true
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    volumes:
      - ./packet_forwarder/configs:/opt/packet_forwarder/configs
      - ./packet_forwarder/tools:/opt/packet_forwarder/tools
    restart: unless-stopped
EOF

echo "Compose file updated."
echo

#--------------------------------------------------
# Restart Docker services
#--------------------------------------------------

echo "Restarting gateway..."

docker-compose -f "$COMPOSE" down || true
docker-compose -f "$COMPOSE" up -d

sleep 5

echo
echo "Current containers:"
docker ps

echo
echo "=========================================="
echo " TTN UDP Gateway ready"
echo "=========================================="
echo
echo "Gateway EUI:"
echo "$GWID"
echo
echo "TTN server:"
echo "eu1.cloud.thethings.network"
echo
echo "UDP port:"
echo "1700"
echo