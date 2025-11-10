#!/bin/bash
################################################################################
# Deploy on Synology NAS - PRODUCTION
# 
# Purpose: Deploy the production application on Synology NAS (no build required)
# Usage: ./deploy_nas.sh [--detached]
# 
# REQUIREMENTS:
#   - Docker and Docker Compose installed on NAS
#   - set_backend executable already present in this directory
#   - sudo access for Docker commands (if not in administrators group)
################################################################################

set -e  # Exit on error

# Detect Docker and docker-compose paths
DOCKER_BIN=$(which docker 2>/dev/null || echo "/usr/local/bin/docker")
COMPOSE_BIN=$(which docker-compose 2>/dev/null || echo "/usr/local/bin/docker-compose")

# Detect if sudo is needed for Docker
DOCKER_CMD="$DOCKER_BIN"
COMPOSE_CMD="$COMPOSE_BIN"

# Project name for Container Manager
PROJECT_NAME="setprod"

# Try without sudo first
if $DOCKER_BIN ps >/dev/null 2>&1; then
    echo "Docker accessible without sudo"
    COMPOSE_CMD="$COMPOSE_BIN -p $PROJECT_NAME"
# Try with passwordless sudo (non-interactive) using full path
elif sudo -n $DOCKER_BIN ps >/dev/null 2>&1; then
    echo "Using passwordless sudo for Docker commands"
    DOCKER_CMD="sudo -n $DOCKER_BIN"
    COMPOSE_CMD="sudo -n $COMPOSE_BIN -p $PROJECT_NAME"
else
    echo "ERROR: Cannot access Docker"
    echo "Docker binary: $DOCKER_BIN"
    echo "Compose binary: $COMPOSE_BIN"
    echo ""
    echo "Please ensure:"
    echo "  1. Docker is installed and running"
    echo "  2. User has passwordless sudo configured for Docker"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DETACHED=false

for arg in "$@"; do
    case $arg in
        --detached|-d)
            DETACHED=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./deploy_nas.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --detached   Run containers in detached mode"
            echo "  --help       Show this help message"
            echo ""
            echo "This script is meant to run ON the Synology NAS."
            echo "Make sure 'set_backend' executable is present before running."
            exit 0
            ;;
    esac
done

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Synology NAS Deployment${NC}"
echo -e "${BLUE}  PRODUCTION ENVIRONMENT${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Verify required files
echo -e "${YELLOW}[1/2] Verifying required files...${NC}"

if [ ! -f ".env" ]; then
    echo -e "${RED}ERROR: .env file not found${NC}"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}ERROR: docker-compose.yml not found${NC}"
    exit 1
fi

if [ ! -f "set_backend" ]; then
    echo -e "${RED}ERROR: set_backend executable not found${NC}"
    echo -e "${YELLOW}You need to build it locally and transfer it here first.${NC}"
    echo "Run on your dev machine:"
    echo "  cd src/env_prod"
    echo "  ./build_and_collect.sh"
    echo "  ./transfer_to_nas.sh"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}ERROR: Dockerfile not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required files present${NC}"
echo ""

# Step 1.5: Ensure required directories exist
echo -e "${YELLOW}[1.5/4] Ensuring required directories exist...${NC}"

# Get the parent directory (should be /volume1/docker/setprod)
DEPLOY_DIR=$(pwd)
PARENT_DIR=$(dirname "$DEPLOY_DIR")

# Create MongoDB directories
MONGODB_DATA_DIR="$PARENT_DIR/mongodb/data"
MONGODB_INIT_DIR="$PARENT_DIR/mongodb/init"

if [ ! -d "$MONGODB_DATA_DIR" ]; then
    echo "  Creating MongoDB data directory: $MONGODB_DATA_DIR"
    mkdir -p "$MONGODB_DATA_DIR"
    echo -e "${GREEN}✓ Created $MONGODB_DATA_DIR${NC}"
else
    echo "  MongoDB data directory exists: $MONGODB_DATA_DIR"
fi

if [ ! -d "$MONGODB_INIT_DIR" ]; then
    echo "  Creating MongoDB init directory: $MONGODB_INIT_DIR"
    mkdir -p "$MONGODB_INIT_DIR"
    echo -e "${GREEN}✓ Created $MONGODB_INIT_DIR${NC}"
else
    echo "  MongoDB init directory exists: $MONGODB_INIT_DIR"
fi

# Create backend data directory
BACKEND_DATA_DIR="$DEPLOY_DIR/data"

if [ ! -d "$BACKEND_DATA_DIR" ]; then
    echo "  Creating backend data directory: $BACKEND_DATA_DIR"
    mkdir -p "$BACKEND_DATA_DIR"
    echo -e "${GREEN}✓ Created $BACKEND_DATA_DIR${NC}"
else
    echo "  Backend data directory exists: $BACKEND_DATA_DIR"
fi

echo -e "${GREEN}✓ All required directories ready${NC}"
echo ""

# Step 2: Stop services and clean up backend container/image
echo -e "${YELLOW}[2/4] Stopping services and cleaning backend container/image...${NC}"

# Stop all services (try both with and without project name for compatibility)
echo "  Stopping docker-compose services..."
$COMPOSE_CMD down 2>/dev/null || true
# Also try without project name to catch old deployments
if [[ "$DOCKER_CMD" == "sudo -n $DOCKER_BIN" ]]; then
    sudo -n $COMPOSE_BIN down 2>/dev/null || true
else
    $COMPOSE_BIN down 2>/dev/null || true
fi

# Force remove backend container if it exists (handle both old and new names)
echo "  Removing backend container (if exists)..."
$DOCKER_CMD rm -f setprod-backend 2>/dev/null || true
$DOCKER_CMD rm -f backend-container 2>/dev/null || true

# Force remove backend image if it exists
echo "  Removing backend image (if exists)..."
$DOCKER_CMD rmi -f setprod-backend:0.7.0 2>/dev/null || true
$DOCKER_CMD rmi -f backend-backend-container 2>/dev/null || true

# Remove dangling images (unnamed intermediate images from builds)
echo "  Removing dangling build images..."
$DOCKER_CMD image prune -f >/dev/null 2>&1 || true

# Remove the old network if it exists without external flag
echo "  Removing old network (if exists)..."
$DOCKER_CMD network rm prod-network 2>/dev/null || true

echo -e "${GREEN}✓ Backend cleanup complete (MongoDB containers preserved)${NC}"
echo ""

# Deploy with Docker Compose
echo -e "${YELLOW}[3/4] Building and deploying backend...${NC}"

if [ "$DETACHED" = true ]; then
    $COMPOSE_CMD up --build -d
    echo ""
    echo -e "${GREEN}=== Deployment Complete (Detached Mode) ===${NC}"
    echo ""
    echo "Services running:"
    $COMPOSE_CMD ps
    echo ""
    echo "View logs with:"
    echo "  $COMPOSE_CMD logs -f"
else
    echo -e "${BLUE}Starting in foreground mode (Ctrl+C to stop)...${NC}"
    echo ""
    $COMPOSE_CMD up --build
fi

echo ""
echo -e "${YELLOW}[4/4] Verifying deployment...${NC}"
sleep 2
echo "Container status:"
$COMPOSE_CMD ps --format table
echo ""
echo -e "${GREEN}Application available at:${NC}"
echo "  - Backend (public): https://set.souchefr.synology.me"
echo ""
echo -e "${YELLOW}Note: This is PRODUCTION - Monitor logs and health checks${NC}"
