#!/bin/bash

################################################################################
# Rust Development Environment - Version 0.4
# Master Deployment Script (Bash)
#
# This script orchestrates deployment to different environments using
# environment-specific configuration files.
#
# Usage:
#   ./deploy-v04.sh --dev      # Deploy development environment
#   ./deploy-v04.sh --test     # Deploy test environment (Synology NAS)
#   ./deploy-v04.sh --prod     # Deploy production environment (Synology NAS)
#
# Each environment has its own:
#   - .env file with environment-specific configuration
#   - docker-compose file optimized for that environment
#   - deployment script with environment-specific logic
################################################################################

set -e  # Exit on any error

# Color codes for symbols only
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo "ℹ $1"
}

show_usage() {
    echo "Usage: $0 [--dev|--test|--prod]"
    echo ""
    echo "Options:"
    echo "  --dev       Deploy development environment (local laptop)"
    echo "  --test      Deploy test environment (Synology NAS)"
    echo "  --prod      Deploy production environment (Synology NAS)"
    echo ""
    echo "Examples:"
    echo "  $0 --dev       # Deploy to local development laptop"
    echo "  $0 --test      # Deploy to Synology NAS (test)"
    echo "  $0 --prod      # Deploy to Synology NAS (production)"
    echo ""
}

################################################################################
# Main Script
################################################################################

print_header "Rust Development Environment v0.4 - Deployment"

# Parse command line arguments
if [ $# -eq 0 ]; then
    print_error "No environment specified"
    show_usage
    exit 1
fi

case "$1" in
    --dev)
        ENVIRONMENT="dev"
        ENV_DIR="$SCRIPT_DIR/dev"
        print_success "Selected: Development Environment"
        ;;
    --test)
        ENVIRONMENT="test"
        ENV_DIR="$SCRIPT_DIR/test"
        print_success "Selected: Test Environment (Synology NAS)"
        ;;
    --prod)
        ENVIRONMENT="prod"
        ENV_DIR="$SCRIPT_DIR/prod"
        print_success "Selected: Production Environment (Synology NAS)"
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        print_error "Invalid option: $1"
        show_usage
        exit 1
        ;;
esac

# Verify environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

# Check for required files
DEPLOY_SCRIPT="$ENV_DIR/deploy-$ENVIRONMENT.sh"
if [ ! -f "$DEPLOY_SCRIPT" ]; then
    print_error "Deployment script not found: $DEPLOY_SCRIPT"
    exit 1
fi

# Make deployment script executable
chmod +x "$DEPLOY_SCRIPT"

# Display environment information
print_header "Deployment Configuration"
echo "Environment:     $ENVIRONMENT"
echo "Directory:       $ENV_DIR"
echo "Deploy Script:   $DEPLOY_SCRIPT"
echo ""

# Confirm deployment (skip for dev)
if [ "$ENVIRONMENT" != "dev" ]; then
    print_info "You are about to deploy to $ENVIRONMENT environment"
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Deployment cancelled"
        exit 0
    fi
fi

# Execute environment-specific deployment script
print_header "Executing $ENVIRONMENT Deployment"

# Store current directory
ORIGINAL_DIR=$(pwd)

# Change to environment directory
cd "$ENV_DIR"
bash "$DEPLOY_SCRIPT"

# Return to original directory
cd "$ORIGINAL_DIR"

print_success "Deployment to $ENVIRONMENT environment completed!"
