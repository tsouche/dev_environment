#!/bin/bash

################################################################################
# Rust Development Environment Deployment Script - Version 0.3
# 
# Generic deployment with .env configuration support
# This script automates the deployment of a containerized Rust development
# environment with MongoDB support on Windows 11 using Docker Desktop.
#
# Prerequisites:
# - Docker Desktop installed and running
# - VS Code installed with Remote-SSH extension
# - SSH key generated (id_ed25519.pub)
#
# Usage: bash deploy-v03.sh
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="rust-dev-environment-v03"
DOCKERFILE="dockerfile.v0.2"
COMPOSE_FILE="docker-compose-v03.yml"

# Load .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    print_success ".env file found - loading configuration"
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
else
    print_warning "No .env file found - using defaults from .env.example"
fi

# Set defaults if not in .env
PROJECT_DIR=${PROJECT_DIR:-rust_project}
DB_NAME=${DB_NAME:-rust_app_db}
DB_USER=${DB_USER:-app_user}
DB_PASSWORD=${DB_PASSWORD:-app_password}
COLLECTION_1=${COLLECTION_1:-items}
COLLECTION_2=${COLLECTION_2:-users}
COLLECTION_3=${COLLECTION_3:-data}

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

################################################################################
# Pre-flight Checks
################################################################################

print_header "Running Pre-flight Checks"

# Check if Docker is installed and running
if ! check_command docker; then
    print_error "Docker Desktop is not installed or not in PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker Desktop is not running. Please start Docker Desktop and try again."
    exit 1
fi

print_success "Docker Desktop is running"

# Check if docker-compose is available
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    exit 1
fi

print_success "Docker Compose is available"

################################################################################
# Directory Structure Setup
################################################################################

print_header "Setting Up Directory Structure"

# Create required directories
mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
mkdir -p "$SCRIPT_DIR/docker/mongo-init"
mkdir -p "$SCRIPT_DIR/.ssh"

print_success "Created directory structure"

################################################################################
# SSH Key Setup
################################################################################

print_header "Configuring SSH Authentication"

# Check for SSH public key
SSH_KEY_SOURCE=""
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    SSH_KEY_SOURCE="$HOME/.ssh/id_ed25519.pub"
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    SSH_KEY_SOURCE="$HOME/.ssh/id_rsa.pub"
fi

if [ -n "$SSH_KEY_SOURCE" ]; then
    cp "$SSH_KEY_SOURCE" "$SCRIPT_DIR/authorized_keys"
    print_success "Copied SSH public key from $SSH_KEY_SOURCE"
else
    print_warning "No SSH public key found. Creating a placeholder file."
    print_warning "You'll need to add your SSH public key to 'authorized_keys' file before building."
    echo "# Add your SSH public key here (id_ed25519.pub or id_rsa.pub)" > "$SCRIPT_DIR/authorized_keys"
    echo ""
    echo "To generate an SSH key, run:"
    echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo ""
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi

################################################################################
# MongoDB Initialization Script
################################################################################

print_header "Creating MongoDB Initialization Script"

cat > "$SCRIPT_DIR/docker/mongo-init/01-init-db.js" << EOF
// MongoDB initialization script for Rust application database
// This script creates the application user and database
// Configuration is loaded from environment variables

db = db.getSiblingDB('${DB_NAME}');

// Create application user with read/write permissions
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

// Create initial collections (examples - customize for your project)
db.createCollection('${COLLECTION_1}');
db.createCollection('${COLLECTION_2}');
db.createCollection('${COLLECTION_3}');

print('Database initialized successfully');
print('Database: ${DB_NAME}');
print('User: ${DB_USER}');
print('Collections: ${COLLECTION_1}, ${COLLECTION_2}, ${COLLECTION_3}');
EOF

print_success "Created MongoDB initialization script"

################################################################################
# Create Sample Rust Project
################################################################################

print_header "Creating Sample Rust Project Structure"

# Create a basic Cargo.toml if it doesn't exist
if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" ]; then
    cat > "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" << EOF
[package]
name = "${PROJECT_NAME:-rust_project}"
version = "0.1.0"
edition = "2024"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
EOF

    print_success "Created Cargo.toml"
else
    print_success "Cargo.toml already exists"
fi

# Create a basic main.rs if it doesn't exist
if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" ]; then
    cat > "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" << 'EOF'
use mongodb::{Client, options::ClientOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Rust Development Environment - Version 0.3");
    
    // Get MongoDB URI from environment
    let mongodb_uri = std::env::var("MONGODB_URI")
        .unwrap_or_else(|_| "mongodb://localhost:27017".to_string());
    
    println!("Connecting to MongoDB at: {}", mongodb_uri);
    
    // Parse connection string
    let client_options = ClientOptions::parse(&mongodb_uri).await?;
    
    // Create client
    let client = Client::with_options(client_options)?;
    
    // List databases to verify connection
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
    print_success "src/main.rs already exists"
fi

################################################################################
# Fix docker-compose-v03.yml
################################################################################

print_header "Verifying Docker Compose Configuration"

# Check if Dockerfile name needs to be updated in docker-compose-v03.yml
if grep -q "dockerfile: Dockerfile" "$SCRIPT_DIR/$COMPOSE_FILE"; then
    print_warning "Updating Dockerfile reference in docker-compose-v03.yml"
    sed -i.bak "s/dockerfile: Dockerfile/dockerfile: $DOCKERFILE/" "$SCRIPT_DIR/$COMPOSE_FILE"
    print_success "Updated docker-compose-v03.yml"
fi

################################################################################
# Build and Deploy
################################################################################

print_header "Building Docker Images"

cd "$SCRIPT_DIR"

# Build the development container
docker compose build

print_success "Docker images built successfully"

################################################################################
# Start Services
################################################################################

print_header "Starting Services"

# Start all services in detached mode
docker compose up -d

print_success "Services started successfully"

# Wait for services to be healthy
echo ""
echo "Waiting for services to be ready..."
sleep 5

################################################################################
# Display Status
################################################################################

print_header "Deployment Summary"

# Show running containers
docker compose ps

echo ""
print_success "Development environment deployed successfully!"
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "  - SSH Access:        localhost:${SSH_PORT:-2222} (user: ${USERNAME:-rustdev})"
echo "  - Application:       http://localhost:${APP_PORT:-8080}"
echo "  - MongoDB:           localhost:${MONGO_PORT:-27017}"
echo "  - Mongo Express:     http://localhost:${MONGO_EXPRESS_PORT:-8081} (user: ${MONGO_EXPRESS_USER:-dev})"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  - Project Directory: $PROJECT_DIR"
echo "  - Database Name:     $DB_NAME"
echo "  - Database User:     $DB_USER"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Configure VS Code Remote-SSH to connect to localhost:${SSH_PORT:-2222}"
echo "  2. Connect to 'rust-dev' container via VS Code"
echo "  3. Open /workspace/$PROJECT_DIR in VS Code"
echo "  4. Run 'cargo build' to verify setup"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  - View logs:         docker compose logs -f"
echo "  - Stop services:     docker compose down"
echo "  - Restart services:  docker compose restart"
echo "  - Shell access:      docker compose exec rust-dev bash"
echo ""

################################################################################
# VS Code SSH Configuration Helper
################################################################################

print_header "VS Code SSH Configuration"

cat << EOF
Add this to your VS Code SSH config file (~/.ssh/config):

Host rust-dev-container
    HostName localhost
    Port ${SSH_PORT:-2222}
    User ${USERNAME:-rustdev}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Then in VS Code:
1. Press Ctrl+Shift+P
2. Type "Remote-SSH: Connect to Host"
3. Select "rust-dev-container"
4. Open folder: /workspace/$PROJECT_DIR
EOF

print_success "Deployment complete!"
