#!/bin/bash
################################################################################
# Transfer to Synology NAS
# 
# Purpose: Transfer deployment files to Synology NAS via Tailscale
# Usage: ./transfer_to_nas.sh <nas_ip> [nas_user] [ssh_port]
# 
# NOTE: Run this on your LOCAL MACHINE after building
# 
# Tailscale Network Setup:
#   NAS Tailscale IP: 100.100.10.1
#   SSH Port: 5522
#   Default User: thierry
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: ./transfer_to_nas.sh <nas_ip> [nas_user] [ssh_port]"
    echo ""
    echo "Arguments:"
    echo "  nas_ip      Tailscale IP address of Synology NAS"
    echo "  nas_user    SSH username (default: thierry)"
    echo "  ssh_port    SSH port (default: 5522)"
    echo ""
    echo "Example:"
    echo "  ./transfer_to_nas.sh 100.100.10.1 thierry 5522"
    echo "  ./transfer_to_nas.sh 100.100.10.1"
    exit 1
fi

NAS_HOST=$1
NAS_USER=${2:-thierry}
NAS_SSH_PORT=${3:-5522}
NAS_PATH="/volume1/docker/settest/backend"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Transfer to Synology NAS${NC}"
echo -e "${BLUE}  via Tailscale Network${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Target: $NAS_USER@$NAS_HOST:$NAS_SSH_PORT"
echo "Path: $NAS_PATH"
echo ""

# Verify executable exists
if [ ! -f "set_backend" ]; then
    echo -e "${RED}ERROR: Executable 'set_backend' not found${NC}"
    echo -e "${YELLOW}Build it first:${NC}"
    echo "  ./build_and_collect.sh"
    exit 1
fi

# Create remote directory if needed
echo -e "${YELLOW}Creating remote directory (if needed)...${NC}"
ssh -p $NAS_SSH_PORT "$NAS_USER@$NAS_HOST" "mkdir -p $NAS_PATH"

# Transfer files
echo -e "${YELLOW}Transferring files...${NC}"

FILES=(
    "set_backend"
    "Dockerfile"
    "docker-compose.yml"
    ".env"
    "deploy_nas.sh"
    "clean.sh"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Copying $file..."
        scp -P $NAS_SSH_PORT "$file" "$NAS_USER@$NAS_HOST:$NAS_PATH/"
    else
        echo -e "  ${YELLOW}Warning: $file not found, skipping${NC}"
    fi
done

# Make scripts executable on NAS
echo -e "${YELLOW}Setting permissions on NAS...${NC}"
ssh -p $NAS_SSH_PORT "$NAS_USER@$NAS_HOST" "chmod +x $NAS_PATH/*.sh && chmod +x $NAS_PATH/set_backend"

echo ""
echo -e "${GREEN}=== Transfer Complete ===${NC}"
echo ""
echo "Next steps (on NAS):"
echo "  ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST"
echo "  cd $NAS_PATH"
echo "  ./deploy_nas.sh --detached"
