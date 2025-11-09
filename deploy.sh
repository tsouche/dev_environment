#!/bin/bash

################################################################################
# Rust Development Environment - Master Deployment Script (Bash)
#
# This script automatically deploys the latest version of the environment.
# Currently: v0.4
#
# Usage:
#   ./deploy.sh --dev      # Deploy development environment
#   ./deploy.sh --test     # Deploy test environment (Synology NAS)
#   ./deploy.sh --prod     # Deploy production environment (Synology NAS)
################################################################################

set -e

# Script directory (root of env_builder)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Latest version
LATEST_VERSION="v0.4"

################################################################################
# Color Codes
################################################################################

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================"
    echo -e "$1"
    echo -e "========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: ./deploy.sh [--dev|--test|--prod]"
    echo ""
    echo "Options:"
    echo "  --dev       Deploy development environment (local laptop)"
    echo "  --test      Deploy test environment (Synology NAS)"
    echo "  --prod      Deploy production environment (Synology NAS)"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh --dev       # Deploy to local development laptop"
    echo "  ./deploy.sh --test      # Deploy to Synology NAS (test)"
    echo "  ./deploy.sh --prod      # Deploy to Synology NAS (production)"
    echo ""
    echo "Current version: $LATEST_VERSION"
    echo ""
}

################################################################################
# Main Script
################################################################################

print_header "Rust Development Environment - Master Deployment"

# Check if no arguments provided
if [ $# -eq 0 ]; then
    print_error "No environment specified"
    show_usage
    exit 1
fi

ENVIRONMENT=$1

# Show help
if [ "$ENVIRONMENT" == "-h" ] || [ "$ENVIRONMENT" == "--help" ]; then
    show_usage
    exit 0
fi

# Validate environment argument
if [ "$ENVIRONMENT" != "--dev" ] && [ "$ENVIRONMENT" != "--test" ] && [ "$ENVIRONMENT" != "--prod" ]; then
    print_error "Invalid option: $ENVIRONMENT"
    show_usage
    exit 1
fi

# Display version information
print_success "Using latest version: $LATEST_VERSION"
echo ""

# Construct path to version-specific deployment script
VERSION_SCRIPT="$SCRIPT_DIR/$LATEST_VERSION/deploy-v04.sh"

# Verify version script exists
if [ ! -f "$VERSION_SCRIPT" ]; then
    print_error "Version deployment script not found: $VERSION_SCRIPT"
    echo "Please ensure $LATEST_VERSION directory exists and contains the deployment script."
    exit 1
fi

# Make version script executable
chmod +x "$VERSION_SCRIPT"

# Store current directory
ORIGINAL_DIR=$(pwd)

# Execute version-specific deployment script
echo -e "${CYAN}Executing: $VERSION_SCRIPT $ENVIRONMENT${NC}"
echo ""

if bash "$VERSION_SCRIPT" "$ENVIRONMENT"; then
    # Ensure we're back in the original directory
    cd "$ORIGINAL_DIR"
    
    echo ""
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed"
    cd "$ORIGINAL_DIR"
    exit 1
fi
