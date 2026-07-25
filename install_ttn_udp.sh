#!/bin/bash

set -e  # Exit on error

SCRIPT_VERSION="1.0.0"

echo "=========================================="
echo " Bobcat 300 -> TTN UDP Gateway Installer"
echo " Version ${SCRIPT_VERSION}"
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

# Get hostname
HOSTNAME=$(hostname)

# Create installation directory
INSTALL_DIR="/opt/bobcat-ttn"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Detected hostname: $HOSTNAME"
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

# CLEANUP: Handle existing installations
echo "=========================================="
echo " Cleaning up existing installations"
echo "=========================================="
echo ""

# Stop Docker daemon first
echo "Stopping Docker service..."
systemctl stop docker || true
sleep 2

# Remove old installation directory if it exists
echo "Removing previous installation files if present..."

if [ -d "$INSTALL_DIR/Bobcat300-DebianMinimalDocker" ]; then
    echo "  Removing Bobcat300-DebianMinimalDocker..."
    rm -rf "$INSTALL_DIR/Bobcat300-DebianMinimalDocker"
fi

if [ -d "$INSTALL_DIR/Bobcat300-DebianMinimalDocker-main" ]; then
    echo "  Removing Bobcat300-DebianMinimalDocker-main..."
    rm -rf "$INSTALL_DIR/Bobcat300-DebianMinimalDocker-main"
fi

if [ -f "$INSTALL_DIR/main.zip" ]; then
    echo "  Removing main.zip..."
    rm -f "$INSTALL_DIR/main.zip"
fi

# Start Docker daemon again
echo "Starting Docker service..."
systemctl start docker || true
sleep 2

# Clean up all Docker containers and images
echo "Cleaning up Docker containers and images..."
docker stop $(docker ps -q 2>/dev/null) 2>/dev/null || true
docker rm $(docker ps -aq 2>/dev/null) 2>/dev/null || true
docker system prune -af --volumes 2>/dev/null || true

echo "Cleanup complete!"
echo ""

# Install required packages
echo "=========================================="
echo " Installing required packages"
echo "=========================================="
echo ""

echo "Checking and installing Docker, Docker Compose, wget, unzip..."
apt update
apt install -y docker.io docker-compose wget unzip

# Start and enable Docker service
systemctl start docker
systemctl enable docker

echo "Packages installed!"
echo ""

# Download repository
echo "=========================================="
echo " Downloading Bobcat300-DebianMinimalDocker"
echo "=========================================="
echo ""

cd "$INSTALL_DIR"

echo "Downloading repository..."
wget -q https://github.com/sicXnull/Bobcat300-DebianMinimalDocker/archive/refs/heads/main.zip

if [ ! -f main.zip ]; then
    echo "ERROR: Download failed."
    exit 1
fi

unzip -q main.zip || {
    echo "ERROR: Failed to extract repository."
    exit 1
}
mv Bobcat300-DebianMinimalDocker-main Bobcat300-DebianMinimalDocker
rm -f main.zip
if [ ! -d "$INSTALL_DIR/Bobcat300-DebianMinimalDocker" ]; then
    echo "ERROR: Repository extraction failed."
    exit 1
fi

REPO="$INSTALL_DIR/Bobcat300-DebianMinimalDocker"
if [ ! -f "$REPO/$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE not found."
    exit 1
fi
cd "$REPO"

echo "Repository downloaded to: $REPO"
echo ""

# Start containers
echo "=========================================="
echo " Starting Docker containers"
echo "=========================================="
echo ""

echo "Starting Docker containers..."
echo "This may take several minutes. Please wait..."
export COMPOSE_HTTP_TIMEOUT=300
docker-compose -f "$COMPOSE_FILE" up -d

# Wait until containers are ready
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

# Configure gateway
echo ""
echo "=========================================="
echo " Configuring TTN gateway"
echo "=========================================="
echo ""

echo "Updating configuration..."
CONFIG="$REPO/packet_forwarder/configs/global_conf.json"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: global_conf.json not found at $CONFIG"
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

echo "Network Interface: $IFACE"
echo "MAC Address: $MAC"
echo "Gateway EUI: $GWID"
echo ""

# Update TTN configuration with selected region
echo "Applying TTN configuration..."
sed -i \
    -e "s/\"gateway_ID\": \".*\"/\"gateway_ID\": \"$GWID\"/" \
    -e "s/\"server_address\": \".*\"/\"server_address\": \"$TTN_SERVER\"/" \
    -e 's/"serv_port_up":.*/"serv_port_up": 1700,/' \
    -e 's/"serv_port_down":.*/"serv_port_down": 1700,/' \
    "$CONFIG"

# Restart containers to apply new config
echo "Restarting containers with new configuration..."
docker-compose -f "$COMPOSE_FILE" restart

echo "Waiting for containers to restart..."
sleep 10

if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    echo ""
    echo "ERROR: Containers are not running."
    docker-compose -f "$COMPOSE_FILE" ps
    exit 1
fi

# Final status
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
echo "NEXT STEPS:"
echo ""
echo "1. Register your gateway in TTN Console:"
echo "   https://console.cloud.thethings.network/"
echo ""
echo "2. Use this Gateway EUI: $GWID"
echo ""
echo "3. Verify the gateway is online"
echo ""
echo "USEFUL COMMANDS:"
echo ""
echo "View logs:"
echo "  cd $REPO"
echo "  docker-compose logs -f"
echo ""
echo "Check gateway info:"
echo "  showgatewayinfo.sh"
echo ""
echo "Stop gateway:"
echo "  cd $REPO"
echo "  docker-compose down"
echo ""
