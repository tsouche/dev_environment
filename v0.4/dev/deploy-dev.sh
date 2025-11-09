#!/bin/bash

################################################################################
# Development Environment Deployment Script - v0.4
# Deploys to local development laptop
################################################################################

set -e

# Color codes for symbols only
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

PROJECT_DIR=${PROJECT_DIR:-rust_project}
DB_NAME=${DB_NAME:-rust_app_db}
DB_USER=${DB_USER:-app_user}
DB_PASSWORD=${DB_PASSWORD:-app_password}
COLLECTION_1=${COLLECTION_1:-items}
COLLECTION_2=${COLLECTION_2:-users}
COLLECTION_3=${COLLECTION_3:-data}

print_header "Development Environment Deployment"

################################################################################
# Check for Existing Project Directory
################################################################################

EXISTING_PROJECT_PATH="${PROJECT_PATH}/${PROJECT_DIR}"
if [ -d "$EXISTING_PROJECT_PATH" ]; then
    echo ""
    print_warning "Existing project directory found: $EXISTING_PROJECT_PATH"
    echo ""
    echo "This directory will be mounted to the container and may contain old files."
    echo "Options:"
    echo "  1. Keep existing directory"
    echo "  2. Delete and start fresh (default)"
    echo "  3. Cancel deployment"
    echo ""
    read -p "Enter choice (1/2/3) [2]: " choice
    
    if [ "$choice" == "3" ]; then
        echo "Deployment cancelled."
        exit 0
    elif [ "$choice" == "1" ]; then
        print_success "Keeping existing project directory"
    else
        echo "Deleting existing project directory..."
        rm -rf "$EXISTING_PROJECT_PATH"
        print_success "Project directory deleted"
    fi
    echo ""
fi

################################################################################
# Create Directories
################################################################################

print_header "Creating Directory Structure"
mkdir -p "${PROJECT_PATH}"
mkdir -p "$SCRIPT_DIR/mongo-init"
mkdir -p "${VOLUME_MONGODB_DATA}"
mkdir -p "${VOLUME_MONGODB_INIT}"
mkdir -p "${VOLUME_CARGO_CACHE}"
mkdir -p "${VOLUME_TARGET_CACHE}"
print_success "Directories created"

echo ""
print_warning "The project directory will NOT be pre-created."
print_warning "You should clone the repository from within VS Code after connecting."
echo ""

################################################################################
# SSH Key Setup
################################################################################

print_header "Configuring SSH Authentication"

SSH_KEY_SOURCE=""
SSH_PRIVATE_KEY=""
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    SSH_KEY_SOURCE="$HOME/.ssh/id_ed25519.pub"
    SSH_PRIVATE_KEY="$HOME/.ssh/id_ed25519"
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    SSH_KEY_SOURCE="$HOME/.ssh/id_rsa.pub"
    SSH_PRIVATE_KEY="$HOME/.ssh/id_rsa"
fi

if [ -n "$SSH_KEY_SOURCE" ]; then
    cp "$SSH_KEY_SOURCE" "$SCRIPT_DIR/../common/authorized_keys"
    print_success "Copied SSH public key: $SSH_KEY_SOURCE"
else
    print_warning "No SSH key found - creating placeholder"
    print_warning "Generate a key with: ssh-keygen -t ed25519 -C 'your_email@example.com'"
    echo "# Add your SSH public key here" > "$SCRIPT_DIR/../common/authorized_keys"
fi

################################################################################
# Configure SSH Config for VS Code
################################################################################

print_header "Configuring VS Code SSH Connection"

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Check if rust-dev host already exists
if ! grep -q "Host rust-dev" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << EOF

# Rust Development Environment v0.4 - Auto-generated
Host rust-dev
    HostName localhost
    Port ${SSH_PORT}
    User ${USERNAME}
    IdentityFile ${SSH_PRIVATE_KEY}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
    print_success "Added 'rust-dev' to SSH config: $SSH_CONFIG"
else
    print_success "SSH config 'rust-dev' already exists in: $SSH_CONFIG"
fi

################################################################################
# MongoDB Init Script
################################################################################

print_header "Creating MongoDB Initialization Script"

cat > "$SCRIPT_DIR/mongo-init/01-init-db.js" << EOF
db = db.getSiblingDB('${DB_NAME}');

db.createUser({
    user: '${DB_USER}',
    pwd: '${DB_PASSWORD}',
    roles: [
        {
            role: 'readWrite',
            db: '${DB_NAME}'
        }
    ]
});

db.createCollection('${COLLECTION_1}');
db.createCollection('${COLLECTION_2}');
db.createCollection('${COLLECTION_3}');

print('Database initialized: ${DB_NAME}');
EOF

# Copy to the mounted volume location
cp "$SCRIPT_DIR/mongo-init/01-init-db.js" "${VOLUME_MONGODB_INIT}/01-init-db.js"

print_success "MongoDB init script created and copied to volume location"

################################################################################
# Create Sample Project
################################################################################

print_header "Skipping Sample Project Creation"
print_warning "The actual project should be cloned from git repository:"
echo "  Repository: ${GIT_REPO}"
echo ""
print_warning "Clone the repository after connecting to the container via VS Code."
echo ""

################################################################################
# Build and Deploy
################################################################################

print_header "Building Docker Images"
docker compose -f docker-compose-dev.yml build
print_success "Images built"

print_header "Starting Services"
docker compose -f docker-compose-dev.yml up -d
print_success "Services started"

sleep 3

################################################################################
# Display Status
################################################################################

print_header "Deployment Complete - Development Environment"
docker compose -f docker-compose-dev.yml ps

echo ""
print_success "Development environment is ready!"
echo ""
echo "Service URLs:"
echo "  - SSH Access:        localhost:${SSH_PORT:-2222} (user: ${USERNAME:-rustdev})"
echo "  - Application:       http://localhost:${APP_PORT:-5665}"
echo "  - MongoDB:           localhost:${MONGO_PORT:-27017}"
echo "  - Mongo Express:     http://localhost:${MONGO_EXPRESS_PORT:-8080}"
echo ""
echo "Configuration:"
echo "  - Environment:       DEV"
echo "  - Container:         ${CONTAINER_NAME:-dev-container}"
echo "  - Workspace:         /workspace"
echo "  - Project Path:      ${PROJECT_PATH}"
echo "  - Database:          $DB_NAME"
echo ""
echo "Next Steps:"
echo "  1. In VS Code, press Ctrl+Shift+P"
echo "  2. Type 'Remote-SSH: Connect to Host'"
echo "  3. Select 'rust-dev'"
echo "  4. Open folder: /workspace"
echo "  5. Clone repository: ${GIT_REPO}"
echo "     git clone ${GIT_REPO}"
echo "  6. Open the cloned project: /workspace/$PROJECT_DIR"
echo "  7. Run: cargo build"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
print_warning "Clone the repository FROM WITHIN the container (via VS Code terminal)"
print_warning "DO NOT clone on Windows and mount it - this causes WSL mount issues!"
echo ""
echo "SSH Configuration:"
echo "  - Host alias:        rust-dev"
echo "  - Config file:       ~/.ssh/config"
echo "  - Identity file:     $SSH_PRIVATE_KEY"
echo ""
echo "Useful Commands:"
echo "  - Logs:      docker compose -f docker-compose-dev.yml logs -f"
echo "  - Stop:      docker compose -f docker-compose-dev.yml down"
echo "  - Restart:   docker compose -f docker-compose-dev.yml restart"
echo "  - Shell:     docker compose -f docker-compose-dev.yml exec dev-container bash"
echo ""
