#!/bin/bash

################################################################################
# Test Environment Deployment Script - v0.4
# Deploys to Synology NAS for testing
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

print_header "Test Environment Deployment (Synology NAS)"

################################################################################
# Create Directories
################################################################################

print_header "Creating Directory Structure"
mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
mkdir -p "$SCRIPT_DIR/mongo-init"
print_success "Directories created"

################################################################################
# No SSH Setup for Test
################################################################################

print_header "SSH Configuration"
print_warning "SSH disabled in test environment"
print_warning "Use 'docker compose exec backend-container bash' for shell access"

# Create placeholder authorized_keys
echo "# SSH not used in test environment" > "$SCRIPT_DIR/../common/authorized_keys"

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
# Clone GitHub Repository
################################################################################

print_header "Setting Up Project from GitHub"

GITHUB_REPO_URL=${GITHUB_REPO_URL:-}
GITHUB_BRANCH=${GITHUB_BRANCH:-main}

if [ -n "$GITHUB_REPO_URL" ]; then
    # Remove existing project directory if it exists
    if [ -d "$SCRIPT_DIR/$PROJECT_DIR" ]; then
        print_warning "Removing existing project directory"
        rm -rf "$SCRIPT_DIR/$PROJECT_DIR"
    fi
    
    print_success "Cloning repository from $GITHUB_REPO_URL (branch: $GITHUB_BRANCH)"
    
    # Clone the repository
    if git clone --branch "$GITHUB_BRANCH" --single-branch "$GITHUB_REPO_URL" "$SCRIPT_DIR/$PROJECT_DIR"; then
        print_success "Repository cloned successfully"
        
        # Copy VS Code devcontainer configuration
        print_success "Copying VS Code devcontainer configuration"
        mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer"
        cp "$SCRIPT_DIR/../common/.devcontainer/devcontainer.json" \
           "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer/" 2>/dev/null || true
    else
        echo "Failed to clone repository. Creating placeholder project..."
        mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
        
        cat > "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" << EOF
[package]
name = "${PROJECT_NAME:-rust_project}"
version = "0.1.0"
edition = "2021"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
axum = "0.7"
EOF
        
        # Copy VS Code devcontainer configuration even for placeholder
        mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer"
        cp "$SCRIPT_DIR/../common/.devcontainer/devcontainer.json" \
           "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer/" 2>/dev/null || true
        
        cat > "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" << 'EOF'
use mongodb::{Client, options::ClientOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Rust Backend - v0.4 [TEST]");
    println!("WARNING: Using placeholder code - repository clone failed");
    
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
    
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
EOF
        print_warning "Created placeholder project"
    fi
else
    print_warning "No GitHub repository URL specified - using manual project setup"
    
    # Original manual setup code
    if [ ! -d "$SCRIPT_DIR/$PROJECT_DIR" ]; then
        mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
    fi
    
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
axum = "0.7"
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
    println!("Rust Backend - v0.4 [TEST]");
    
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
    println!("Backend server ready for testing");
    
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
    }
}
EOF
        print_success "Created src/main.rs"
    else
        print_success "src/main.rs exists"
    fi
fi

################################################################################
# Build and Deploy
################################################################################

print_header "Building Docker Images"
docker compose -f docker-compose-test.yml build
print_success "Images built"

print_header "Starting Services"
docker compose -f docker-compose-test.yml up -d
print_success "Services started"

sleep 3

################################################################################
# Display Status
################################################################################

print_header "Deployment Complete - Test Environment"
docker compose -f docker-compose-test.yml ps

echo ""
print_success "Test environment is ready!"
echo ""
echo "Service URLs (Internal):"
echo "  - Application:       http://localhost:${APP_PORT:-5665}"
echo "  - Mongo Express:     http://localhost:${MONGO_EXPRESS_PORT:-8080}"
echo ""
echo "External Access:"
echo "  - Application:       ${EXTERNAL_URL:-https://test_set.domain.synology.me}"
echo ""
echo "Configuration:"
echo "  - Environment:       TEST"
echo "  - Container:         ${CONTAINER_NAME:-backend-container}"
echo "  - Project Dir:       $PROJECT_DIR"
echo "  - Database:          $DB_NAME"
echo ""
echo "Synology Reverse Proxy Setup:"
echo "  1. Go to: Control Panel -> Application Portal -> Reverse Proxy"
echo "  2. Click 'Create'"
echo "  3. Configure:"
echo "     Description:      SET Game Test"
echo "     Source:"
echo "       Protocol:       HTTPS"
echo "       Hostname:       test_set.domain.synology.me"
echo "       Port:           443"
echo "     Destination:"
echo "       Protocol:       HTTP"
echo "       Hostname:       localhost"
echo "       Port:           ${APP_PORT:-5665}"
echo "  4. Enable HSTS and HTTP/2"
echo ""
echo "Useful Commands:"
echo "  - Logs:      docker compose -f docker-compose-test.yml logs -f"
echo "  - Stop:      docker compose -f docker-compose-test.yml down"
echo "  - Restart:   docker compose -f docker-compose-test.yml restart"
echo "  - Shell:     docker compose -f docker-compose-test.yml exec backend-container bash"
echo ""
