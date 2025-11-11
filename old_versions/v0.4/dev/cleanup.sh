#!/bin/bash

################################################################################
# Complete Cleanup Script for Development Environment - v0.4
# WARNING: This will delete ALL development environment data
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo ""
    echo -e "${RED}========================================"
    echo -e "$1"
    echo -e "========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

print_header "COMPLETE CLEANUP - Development Environment"

echo ""
echo -e "${YELLOW}This script will DELETE the following:${NC}"
echo "  - All Docker containers (dev-container, dev-mongodb, dev-mongo-express)"
echo "  - All Docker images related to this project"
echo "  - All Docker networks (dev-network)"
echo "  - Project directory: ${PROJECT_PATH}"
echo "  - MongoDB data: ${VOLUME_MONGODB_DATA}"
echo "  - MongoDB init: ${VOLUME_MONGODB_INIT}"
echo "  - Cargo cache: ${VOLUME_CARGO_CACHE}"
echo "  - Target cache: ${VOLUME_TARGET_CACHE}"
echo "  - Local mongo-init: ${SCRIPT_DIR}/mongo-init"
echo ""
echo -e "${RED}THIS CANNOT BE UNDONE!${NC}"
echo ""

read -p "Type 'YES' to confirm complete cleanup: " confirmation

if [ "$confirmation" != "YES" ]; then
    echo -e "${GREEN}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""

################################################################################
# Stop and Remove Containers
################################################################################

print_header "Stopping and Removing Containers"

cd "$SCRIPT_DIR"
if docker compose -f docker-compose-dev.yml down -v 2>/dev/null; then
    print_success "Containers and networks removed"
else
    print_warning "No running containers found or error stopping them"
fi

################################################################################
# Remove Images
################################################################################

print_header "Removing Docker Images"

for image in "v0.4-dev-container" "common-dev-container" "dev-dev-container"; do
    if docker rmi "$image" -f 2>/dev/null; then
        print_success "Removed image: $image"
    else
        print_warning "Image not found: $image"
    fi
done

################################################################################
# Remove Bind-Mounted Directories
################################################################################

print_header "Removing Bind-Mounted Directories"

declare -A directories=(
    ["${PROJECT_PATH}"]="Project directory"
    ["${VOLUME_MONGODB_DATA}"]="MongoDB data"
    ["${VOLUME_MONGODB_INIT}"]="MongoDB init"
    ["${VOLUME_CARGO_CACHE}"]="Cargo cache"
    ["${VOLUME_TARGET_CACHE}"]="Target cache"
    ["${SCRIPT_DIR}/mongo-init"]="Local mongo-init"
)

for dir_path in "${!directories[@]}"; do
    dir_name="${directories[$dir_path]}"
    if [ -d "$dir_path" ]; then
        if rm -rf "$dir_path" 2>/dev/null; then
            print_success "Removed: $dir_name ($dir_path)"
        else
            print_warning "Failed to remove: $dir_name ($dir_path)"
        fi
    else
        echo -e "${GRAY}[-] Not found: $dir_name ($dir_path)${NC}"
    fi
done

################################################################################
# Docker System Cleanup
################################################################################

print_header "Docker System Cleanup"

echo "Pruning unused Docker data..."
docker system prune -f --volumes 2>/dev/null
print_success "Docker system pruned"

echo "Pruning Docker build cache..."
docker builder prune -f 2>/dev/null
print_success "Docker build cache pruned"

################################################################################
# Verification
################################################################################

print_header "Verification"

echo -e "${CYAN}Remaining containers:${NC}"
docker ps -a --filter "name=dev-" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo -e "${CYAN}Remaining images:${NC}"
docker images --filter "reference=*dev*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo ""
echo -e "${CYAN}Remaining volumes:${NC}"
docker volume ls --filter "name=dev"

echo ""
echo -e "${CYAN}Project directory contents:${NC}"
if [ -d "${PROJECT_PATH}" ]; then
    ls -lah "${PROJECT_PATH}"
else
    echo -e "${GRAY}  (Directory does not exist)${NC}"
fi

################################################################################
# Complete
################################################################################

echo ""
print_header "Cleanup Complete"
echo ""
print_success "All development environment data has been removed."
echo ""
echo -e "${CYAN}To redeploy the environment, run:${NC}"
echo "  ./deploy-dev.sh"
echo ""
