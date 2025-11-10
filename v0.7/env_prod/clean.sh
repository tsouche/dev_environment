#!/bin/bash
################################################################################
# Cleanup Script - PRODUCTION
# 
# Purpose: Stop containers and clean up deployment artifacts
# Usage: ./clean.sh [--volumes] [--all]
# 
# WARNING: This affects PRODUCTION environment
################################################################################

set -e  # Exit on error

# Project name for Container Manager
PROJECT_NAME="setprod"

# Detect if sudo is needed for Docker
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        echo "ERROR: Cannot access Docker even with sudo"
        exit 1
    fi
fi

# Set compose command accordingly
if [[ "$DOCKER_CMD" == "sudo docker" ]]; then
    COMPOSE_CMD="sudo docker-compose -p $PROJECT_NAME"
else
    COMPOSE_CMD="docker-compose -p $PROJECT_NAME"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
REMOVE_VOLUMES=false
REMOVE_ALL=false

for arg in "$@"; do
    case $arg in
        --volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --all)
            REMOVE_ALL=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./clean.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --volumes    Also remove Docker volumes (database data)"
            echo "  --all        Remove everything including executable"
            echo "  --help       Show this help message"
            echo ""
            echo "WARNING: This script affects PRODUCTION environment!"
            exit 0
            ;;
    esac
done

echo -e "${RED}=== WARNING: Cleaning PRODUCTION deployment ===${NC}"
echo ""

# Confirmation for production
read -p "Are you sure you want to stop production containers? (yes/NO): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Stop and remove containers
echo "Stopping containers..."
$COMPOSE_CMD down

# Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ] || [ "$REMOVE_ALL" = true ]; then
    echo -e "${RED}WARNING: About to remove PRODUCTION volumes (database data)${NC}"
    read -p "Type 'DELETE PRODUCTION DATA' to confirm: " volume_confirm
    if [ "$volume_confirm" = "DELETE PRODUCTION DATA" ]; then
        echo -e "${YELLOW}Removing volumes...${NC}"
        $COMPOSE_CMD down -v
        echo -e "${GREEN}✓ Volumes removed${NC}"
    else
        echo "Volume removal cancelled"
    fi
fi

# Remove executable if --all is specified
if [ "$REMOVE_ALL" = true ]; then
    echo -e "${YELLOW}Removing collected executable...${NC}"
    if [ -f "set_backend" ]; then
        rm set_backend
        echo -e "${GREEN}✓ Executable removed${NC}"
    else
        echo "No executable to remove"
    fi
fi

echo -e "${GREEN}=== Cleanup complete ===${NC}"
