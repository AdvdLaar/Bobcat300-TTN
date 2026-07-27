#!/bin/bash
set -e # Exit on error

SCRIPT_VERSION="1.3.8"
INSTALL_DIR="/opt/bobcat-ttn"
REPO_ZIP_URL="https://github.com/AdvdLaar/Bobcat300-TTN/archive/refs/heads/main.zip"

echo "=========================================="
echo " Bobcat 300 -> TTN UDP Gateway Installer"
echo " Version ${SCRIPT_VERSION}"
echo " Source: https://github.com/AdvdLaar/Bobcat300-TTN"
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

case "$REGION" in
    1)
        TTN_SERVER="eu1.cloud.thethings.network"
        BAND="EU868"
        ;;
    2)
        TTN_SERVER="nam1.cloud.thethings.network"
        BAND="US915"
        ;;
    3)
        TTN_SERVER="as1.cloud.thethings.network"
        BAND="AS923"
        ;;
    4)
        TTN_SERVER="au1.cloud.thethings.network"
        BAND="AU915"
        ;;
    5)
        TTN_SERVER="in1.cloud.thethings.network"
        BAND="IN865"
        ;;
    6)
        TTN_SERVER="ru1.cloud.thethings.network"
        BAND="RU864"
        ;;
    7)
        TTN_SERVER="cn1.cloud.thethings.network"
        BAND="CN470"
        ;;
    8)
        TTN_SERVER="jp1.cloud.thethings.network"
        BAND="JP923"
        ;;
    9)
        TTN_SERVER="kr1.cloud.thethings.network"
        BAND="KR920"
        ;;
    *)
        TTN_SERVER="eu1.cloud.thethings.network"
        BAND="EU868"
        ;;
esac

echo "Selected:"
echo "  Frequency Plan : $BAND"
echo "  TTN Server     : $TTN_SERVER"
echo ""

# Get hostname
HOSTNAME=$(hostname)
echo "Detected hostname: $HOSTNAME"
echo ""

# Determine compose file and spidev path based on hostname
case "$HOSTNAME" in

    bobcat-285)
        COMPOSE_FILE="docker-compose-G285.yml"
        SPIDEV_PATH="/dev/spidev1.0"
        ;;

    bobcat-280)
        COMPOSE_FILE="docker-compose-G280.yml"
        SPIDEV_PATH="/dev/spidev1.0"
        ;;

    bobcat-29*|bobcat-g29*)
        COMPOSE_FILE="docker-compose-G29X.yml"
        SPIDEV_PATH="/dev/spidev5.0"
        ;;

    *)
        echo "Error: Unknown hostname '$HOSTNAME'"
        exit 1
        ;;

esac

echo "Using compose file: $COMPOSE_FILE"
echo "SPI device path: $SPIDEV_PATH"
echo ""

# Verify SPI device exists
if [ ! -e "$SPIDEV_PATH" ]; then
    echo "ERROR: SPI device not found: $SPIDEV_PATH"
    echo ""
    echo "The correct kernel or device tree may not be installed."
    exit 1
fi

# ==================================================
# CLEANUP
# ==================================================
echo "=========================================="
echo " Cleaning up existing installations"
echo "=========================================="
echo ""

echo "Stopping existing Docker containers..."
docker stop $(docker ps -q 2>/dev/null) 2>/dev/null || true
docker rm $(docker ps -aq 2>/dev/null) 2>/dev/null || true

echo "Pruning unused Docker resources..."
docker system prune -af --volumes 2>/dev/null || true

# Remove previous installation
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing previous installation at $INSTALL_DIR ..."
    rm -rf "$INSTALL_DIR"
fi

echo "Cleanup complete!"
echo ""

# ==================================================
# INSTALL PACKAGES
# ==================================================
echo "=========================================="
echo " Installing required packages"
echo "=========================================="
echo ""
echo "Checking and installing Docker, Docker Compose, wget, unzip..."

apt update
if ! command -v docker >/dev/null 2>&1; then
    apt install -y docker.io docker-compose
fi

apt install -y wget unzip

systemctl start docker
systemctl enable docker

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not running."
    exit 1
fi

echo "Docker is running."

echo "Packages installed!"
echo ""

# ==================================================
# DOWNLOAD & EXTRACT YOUR REPO
# ==================================================
echo "=========================================="
echo " Downloading repository to $INSTALL_DIR"
echo "=========================================="
echo ""

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Downloading $REPO_ZIP_URL ..."
wget -q "$REPO_ZIP_URL" -O main.zip --show-progress

if [ ! -f main.zip ]; then
    echo "ERROR: Download failed."
    exit 1
fi

echo "Extracting..."
unzip -q main.zip || {
    echo "ERROR: Failed to extract repository."
    exit 1
}

# GitHub creates a folder named Bobcat300-TTN-main
if [ -d "Bobcat300-TTN-main" ]; then
    mv Bobcat300-TTN-main/* .
    mv Bobcat300-TTN-main/.* . 2>/dev/null || true
    rmdir Bobcat300-TTN-main
else
    echo "ERROR: Unexpected folder structure after unzip."
    exit 1
fi

rm -f main.zip

if [ ! -d "$INSTALL_DIR/packet_forwarder" ]; then
    echo "ERROR: packet_forwarder directory not found after extraction."
    exit 1
fi

PACKET_FORWARDER_DIR="$INSTALL_DIR/packet_forwarder"
COMPOSE_PATH="$PACKET_FORWARDER_DIR/$COMPOSE_FILE"


echo "Preparing Bobcat scripts..."

chmod +x "$PACKET_FORWARDER_DIR/packet_forwarder/tools/reset_lgw.sh.bobcat"

if [ ! -f "$COMPOSE_PATH" ]; then
    echo "ERROR: Compose file not found after download:"
    echo "  $COMPOSE_PATH"
    exit 1
fi

echo "Repository downloaded and extracted successfully to $INSTALL_DIR"
echo ""

# Update selected LoRaWAN frequency plan in Docker Compose
echo "Setting frequency plan to $BAND..."
sed -i -E "s/(REGION:[[:space:]]*).*/\1$BAND/" "$COMPOSE_PATH"

echo "Frequency plan updated."
echo ""

# ==================================================
# START CONTAINERS
# ==================================================
echo "=========================================="
echo " Starting Docker containers"
echo "=========================================="
echo ""
echo "Starting Docker containers..."
echo "This may take several minutes. Please wait..."

cd "$INSTALL_DIR"
export COMPOSE_HTTP_TIMEOUT=300
echo "Starting pktfwd container temporarily..."
docker-compose -f "$COMPOSE_PATH" up -d pktfwd
sleep 1
docker-compose -f "$COMPOSE_PATH" down

# Wait until containers are ready
echo "Waiting for gateway initialization..."
WAIT_TIME=0
MAX_WAIT=120
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker-compose -f "$COMPOSE_PATH" ps | grep -q "Up"; then
        echo "Containers are running!"
        break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "WARNING: Containers took longer than $MAX_WAIT seconds to start"
fi

CONFIG="$PACKET_FORWARDER_DIR/packet_forwarder/configs/global_conf.json"

echo "Waiting for global_conf.json..."

WAIT_CONFIG=0
MAX_CONFIG_WAIT=120

while [ ! -f "$CONFIG" ] && [ $WAIT_CONFIG -lt $MAX_CONFIG_WAIT ]; do
    sleep 2
    WAIT_CONFIG=$((WAIT_CONFIG + 2))
done

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json was not created within $MAX_CONFIG_WAIT seconds."
    echo "Check container logs:"
    echo "  docker-compose -f $COMPOSE_FILE logs"
    exit 1
fi

# ==================================================
# CONFIGURE GATEWAY
# ==================================================
echo ""
echo "=========================================="
echo " Configuring TTN gateway"
echo "=========================================="
echo ""
echo "Updating configuration..."

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found at:"
    echo "  $CONFIG"
    echo ""
    echo "The container should have created the configs/ directory next to tools/."
    echo "Check the logs with:"
    echo "  cd $PACKET_FORWARDER_DIR && docker-compose -f $COMPOSE_FILE logs"
    exit 1
fi

echo "Found config at: $CONFIG"

# Backup
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

echo "Network Interface: $IFACE"
echo "MAC Address: $MAC"
echo "Gateway EUI: $GWID"
echo ""

# Apply TTN settings
echo "Applying TTN configuration..."
sed -i \
    -e "s/\"gateway_ID\": \".*\"/\"gateway_ID\": \"$GWID\"/" \
    -e "s/\"server_address\": \".*\"/\"server_address\": \"$TTN_SERVER\"/" \
    -e 's/"serv_port_up":.*/"serv_port_up": 1700,/' \
    -e 's/"serv_port_down":.*/"serv_port_down": 1700,/' \
    "$CONFIG"

# Restart to apply config
echo "Restarting containers with new configuration..."
docker-compose -f "$COMPOSE_PATH" restart

echo "Waiting for containers to restart..."
sleep 10

if ! docker-compose -f "$COMPOSE_PATH" ps | grep -q "Up"; then
    echo ""
    echo "ERROR: Containers are not running."
    docker-compose -f "$COMPOSE_PATH" ps
    exit 1
fi

# ==================================================
# FINAL STATUS
# ==================================================
echo ""
echo "Checking gateway status..."

if docker-compose -f "$COMPOSE_PATH" ps | grep -q "Up"; then
    echo "Status : RUNNING"
else
    echo "Status : FAILED"
fi

echo ""
echo "=========================================="
echo " TTN UDP Gateway Installation Complete!"
echo "=========================================="
echo ""
echo "Gateway successfully configured."
echo ""
echo "Gateway EUI : $GWID"
echo "Region      : $BAND"
echo "TTN Server  : $TTN_SERVER"
echo ""
echo "NEXT STEP"
echo "---------"
echo "Register this gateway in The Things Stack:"
echo ""
echo "https://console.cloud.thethings.network/"
echo ""
echo "Gateway EUI:"
echo "  $GWID"
echo ""
echo "After registration the gateway should appear ONLINE within about a minute."
echo ""
echo "Useful commands:"
echo ""
echo "View live logs:"
echo "  cd $PACKET_FORWARDER_DIR"
echo "  docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "Show gateway information:"
echo "  $INSTALL_DIR/showgatewayinfo.sh"
echo ""