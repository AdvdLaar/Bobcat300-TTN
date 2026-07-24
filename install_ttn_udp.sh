#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo " Bobcat 300 G285 -> TTN UDP Gateway"
echo "=========================================="
echo ""

# TTN Server Region Selection
echo "Select TTN Server region:"
echo ""
echo "1) EU868 (Europe) - eu1.cloud.thethings.network"
echo "2) US915 (North America) - nam1.cloud.thethings.network"
echo "3) AS923 (Southeast Asia) - as1.cloud.thethings.network"
echo "4) AU915 (Australia) - au1.cloud.thethings.network"
echo "5) IN865 (India) - in1.cloud.thethings.network"
echo "6) RU864 (Russia) - ru1.cloud.thethings.network"
echo "7) CN470 (China) - cn1.cloud.thethings.network"
echo "8) JP923 (Japan) - jp1.cloud.thethings.network"
echo "9) KR920 (South Korea) - kr1.cloud.thethings.network"
echo ""
read -p "Select region [1]: " REGION
REGION=${REGION:-1}

case $REGION in
    1) TTN_SERVER="eu1.cloud.thethings.network"; BAND="EU868" ;;
    2) TTN_SERVER="nam1.cloud.thethings.network"; BAND="US915" ;;
    3) TTN_SERVER="as1.cloud.thethings.network"; BAND="AS923" ;;
    4) TTN_SERVER="au1.cloud.thethings.network"; BAND="AU915" ;;
    5) TTN_SERVER="in1.cloud.thethings.network"; BAND="IN865" ;;
    6) TTN_SERVER="ru1.cloud.thethings.network"; BAND="RU864" ;;
    7) TTN_SERVER="cn1.cloud.thethings.network"; BAND="CN470" ;;
    8) TTN_SERVER="jp1.cloud.thethings.network"; BAND="JP923" ;;
    9) TTN_SERVER="kr1.cloud.thethings.network"; BAND="KR920" ;;
    *) TTN_SERVER="eu1.cloud.thethings.network"; BAND="EU868" ;;
esac

echo "Selected: $TTN_SERVER ($BAND)"
echo ""

# Install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
apt-get update
apt-get install -y docker.io docker-compose wget unzip

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Get hostname
HOSTNAME=$(hostname)

# Create installation directory
INSTALL_DIR="/opt/bobcat-ttn"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download repository as ZIP
echo "Downloading Bobcat300-DebianMinimalDocker..."
wget -q https://github.com/sicXnull/Bobcat300-DebianMinimalDocker/archive/refs/heads/main.zip
unzip -q main.zip
mv Bobcat300-DebianMinimalDocker-main Bobcat300-DebianMinimalDocker
rm main.zip

REPO="$INSTALL_DIR/Bobcat300-DebianMinimalDocker"
cd "$REPO"

echo "Repository downloaded to: $REPO"
echo ""

# Determine compose file and spidev path based on hostname
case "$HOSTNAME" in
    bobcat-29x)
        COMPOSE_FILE="docker-compose-G29X.yml"
        SPIDEV_PATH="/dev/spidev5.0"
        ;;
    bobcat-285)
        COMPOSE_FILE="docker-compose-G285.yml"
        SPIDEV_PATH="/dev/spidev1.0"
        ;;
    *)
        echo "Error: Unknown hostname '$HOSTNAME'. Expected 'bobcat-29x' or 'bobcat-285'"
        exit 1
        ;;
esac

echo "Detected hostname: $HOSTNAME"
echo "Using compose file: $COMPOSE_FILE"
echo "SPI device path: $SPIDEV_PATH"
echo ""

# Start containers with extended timeout (300 seconds = 5 minutes)
echo "Starting Docker containers..."
echo "This may take several minutes. Please wait..."
export COMPOSE_HTTP_TIMEOUT=300
docker-compose -f "$COMPOSE_FILE" up -d

# Wait until containers are ready (max 120 seconds)
echo "Waiting for gateway initialization..."
WAIT_TIME=0
MAX_WAIT=120

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo "Containers are running!"
        break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "WARNING: Containers took longer than $MAX_WAIT seconds to start"
fi

# Extra buffer for config generation
sleep 5

echo "Updating configuration..."
CONFIG="$REPO/packet_forwarder/configs/global_conf.json"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found."
    exit 1
fi

# Backup original config
cp "$CONFIG" "$CONFIG.bak"

# Update spidev_path
sed -i "s|\"spidev_path\": \".*\"|\"spidev_path\": \"$SPIDEV_PATH\"|g" "$CONFIG"

# Determine MAC address for Gateway EUI
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

echo "Interface: $IFACE"
echo "MAC Address: $MAC"
echo "Gateway EUI: $GWID"
echo ""

# Update TTN configuration with selected region
echo "Configuring TTN..."
sed -i \
    -e "s/\"gateway_ID\": \".*\"/\"gateway_ID\": \"$GWID\"/" \
    -e "s/\"server_address\": \".*\"/\"server_address\": \"$TTN_SERVER\"/" \
    -e 's/"serv_port_up":.*/"serv_port_up": 1700,/' \
    -e 's/"serv_port_down":.*/"serv_port_down": 1700,/' \
    "$CONFIG"

# Restart containers to apply new config
echo "Restarting containers with new configuration..."
docker-compose -f "$COMPOSE_FILE" restart

# Wait for restart
sleep 10

echo ""
echo "=========================================="
echo " TTN UDP Gateway Installation Complete!"
echo "=========================================="
echo ""
echo "Gateway Information:"
echo "  Hostname: $HOSTNAME"
echo "  Gateway EUI: $GWID"
echo "  TTN Server: $TTN_SERVER"
echo "  Region: $BAND"
echo "  UDP Port: 1700"
echo "  Install Path: $REPO"
echo ""
echo "To view logs:"
echo "  cd $REPO"
echo "  docker-compose logs -f"
echo ""
echo "To stop gateway:"
echo "  cd $REPO"
echo "  docker-compose down"
echo ""
