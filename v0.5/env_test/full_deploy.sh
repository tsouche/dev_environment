#!/bin/bash
################################################################################
# Complete Automated Deployment to Synology DS1821+ via Tailscale
# 
# Purpose: Build, transfer, and deploy to NAS in one command
# Usage: ./full_deploy.sh <nas_ip> [nas_user] [ssh_port] [--release]
# 
# Tailscale Network Setup:
#   NAS Tailscale IP: 100.100.10.1
#   SSH Port: 5522
#   Default User: thierry
# 
# Example:
#   ./full_deploy.sh 100.100.10.1 thierry 5522 --release
#   ./full_deploy.sh 100.100.10.1 thierry --release
#   ./full_deploy.sh 100.100.10.1
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: ./full_deploy.sh <nas_ip> [nas_user] [ssh_port] [--release]"
    echo ""
    echo "Arguments:"
    echo "  nas_ip      Tailscale IP address of Synology NAS"
    echo "  nas_user    SSH username (default: thierry)"
    echo "  ssh_port    SSH port (default: 5522)"
    echo "  --release   Build optimized release version"
    echo ""
    echo "Examples:"
    echo "  ./full_deploy.sh 100.100.10.1"
    echo "  ./full_deploy.sh 100.100.10.1 thierry 5522 --release"
    exit 1
fi

NAS_HOST=$1
NAS_USER=${2:-thierry}
NAS_SSH_PORT=5522
BUILD_TYPE=""

# Parse remaining arguments for port and --release
shift
[ $# -gt 0 ] && shift  # Skip NAS_USER if provided
for arg in "$@"; do
    case $arg in
        --release)
            BUILD_TYPE="--release"
            ;;
        [0-9]*)
            NAS_SSH_PORT=$arg
            ;;
    esac
done

NAS_PATH="/volume1/docker/settest/backend"
TARGET="x86_64-unknown-linux-gnu"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Synology DS1821+ Deployment${NC}"
echo -e "${BLUE}  via Tailscale Network${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "Configuration:"
echo "  NAS IP: $NAS_HOST (Tailscale)"
echo "  NAS User: $NAS_USER"
echo "  SSH Port: $NAS_SSH_PORT"
echo "  Target: $TARGET (AMD Ryzen)"
echo "  Build: ${BUILD_TYPE:-debug}"
echo "  Path: $NAS_PATH"
echo ""

# Step 1: Build executable
echo -e "${YELLOW}[1/6] Building executable for DS1821+...${NC}"
./build_and_collect.sh $BUILD_TYPE

if [ ! -f "set_backend" ]; then
    echo -e "${RED}ERROR: Executable not found after build${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Step 2: Create directories on NAS
echo -e "${YELLOW}[2/6] Creating directory structure on NAS...${NC}"

# Try with sudo first, if fails try without sudo
ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST "
    if sudo -n mkdir -p $NAS_PATH/mongodb/data $NAS_PATH/mongodb/init 2>/dev/null; then
        sudo chown -R $NAS_USER:users $NAS_PATH
        sudo chmod -R 755 $NAS_PATH
        echo 'Created directories with sudo'
    else
        mkdir -p $NAS_PATH/mongodb/data $NAS_PATH/mongodb/init
        chmod -R 755 $NAS_PATH
        echo 'Created directories without sudo'
    fi
" || {
    echo -e "${RED}ERROR: Failed to create directories on NAS${NC}"
    echo -e "${YELLOW}Please create manually:${NC}"
    echo "  ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST"
    echo "  sudo mkdir -p $NAS_PATH/mongodb/data"
    echo "  sudo mkdir -p $NAS_PATH/mongodb/init"
    echo "  sudo chown -R $NAS_USER:users $NAS_PATH"
    exit 1
}

echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Step 3: Upload files
echo -e "${YELLOW}[3/6] Uploading files to NAS...${NC}"

FILES=(
    "set_backend"
    "Dockerfile"
    "docker-compose.yml"
    ".env"
    "deploy_nas.sh"
    "clean.sh"
    "README.md"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Uploading $file..."
        scp -P $NAS_SSH_PORT -q "$file" "$NAS_USER@$NAS_HOST:$NAS_PATH/" || {
            echo -e "${RED}Failed to upload $file${NC}"
            exit 1
        }
    else
        echo -e "  ${YELLOW}Warning: $file not found, skipping${NC}"
    fi
done

echo -e "${GREEN}✓ Upload complete${NC}"
echo ""

# Step 4: Set permissions
echo -e "${YELLOW}[4/6] Setting permissions on NAS...${NC}"
ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST "cd $NAS_PATH && chmod +x *.sh set_backend"

echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 5: Verify setup
echo -e "${YELLOW}[5/6] Verifying deployment files...${NC}"
ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST "cd $NAS_PATH && ls -lh"

# Optional: check file type if command is available
ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST "command -v file >/dev/null 2>&1 && file $NAS_PATH/set_backend || echo 'Note: file command not available on NAS'"

echo ""

# Step 6: Deploy with Docker Compose
echo -e "${YELLOW}[6/6] Deploying with Docker Compose...${NC}"
echo ""
echo "Starting automated deployment..."
ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST "cd $NAS_PATH && ./deploy_nas.sh --detached"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Services available at:"
echo "  Backend (public):  https://settest.souchefr.synology.me"
echo "  Mongo Express:     http://$NAS_HOST:8081 (Tailscale only)"
echo ""
echo "Management:"
echo "  ssh -p $NAS_SSH_PORT $NAS_USER@$NAS_HOST"
echo "  cd $NAS_PATH"
echo "  docker-compose logs -f        # View logs"
echo "  docker-compose ps             # Check status"
echo "  docker-compose restart        # Restart services"
echo "  ./clean.sh                    # Stop services"
