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
# Create Directories
################################################################################

print_header "Creating Directory Structure"
mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
mkdir -p "$SCRIPT_DIR/mongo-init"
print_success "Directories created"

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

print_success "MongoDB init script created"

################################################################################
# Create Sample Project
################################################################################

print_header "Creating Sample Rust Project"

# Copy VS Code devcontainer configuration
print_success "Copying VS Code devcontainer configuration"
mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer"
cp "$SCRIPT_DIR/../common/.devcontainer/devcontainer.json" \
   "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer/" 2>/dev/null || true

if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" ]; then
    cat > "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" << EOF
[package]
name = "${PROJECT_NAME:-rust_project}"
version = "0.1.0"
edition = "2021"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
EOF
    print_success "Created Cargo.toml"
else
    print_success "Cargo.toml exists"
fi

if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" ]; then
    cat > "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" << 'EOF'
use mongodb::{Client, options::ClientOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Rust Development Environment - v0.4 [DEV]");
    
    let mongodb_uri = std::env::var("MONGODB_URI")
        .unwrap_or_else(|_| "mongodb://localhost:27017".to_string());
    
    println!("Connecting to MongoDB at: {}", mongodb_uri);
    
    let client_options = ClientOptions::parse(&mongodb_uri).await?;
    let client = Client::with_options(client_options)?;
    
    let db_names = client.list_database_names(None, None).await?;
    println!("Available databases:");
    for name in db_names {
        println!("  - {}", name);
    }
    
    println!("\nMongoDB connection successful!");
    Ok(())
}
EOF
    print_success "Created src/main.rs"
else
    print_success "src/main.rs exists"
fi

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
echo "  - Project Dir:       $PROJECT_DIR"
echo "  - Database:          $DB_NAME"
echo ""
echo "Next Steps:"
echo "  1. In VS Code, press Ctrl+Shift+P"
echo "  2. Type 'Remote-SSH: Connect to Host'"
echo "  3. Select 'rust-dev'"
echo "  4. Open folder: /workspace/$PROJECT_DIR"
echo "  5. Run: cargo build"
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
