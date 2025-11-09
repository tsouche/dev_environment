#!/bin/bash

################################################################################
# Production Environment Deployment Script - v0.4
# Deploys to Synology NAS for production
# WARNING: This deploys to PRODUCTION - review all settings carefully!
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

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

PROJECT_DIR=${PROJECT_DIR:-rust_project}
DB_NAME=${DB_NAME:-rust_app_db}
DB_USER=${DB_USER:-app_user}
DB_PASSWORD=${DB_PASSWORD}
COLLECTION_1=${COLLECTION_1:-items}
COLLECTION_2=${COLLECTION_2:-users}
COLLECTION_3=${COLLECTION_3:-data}

print_header "⚠️  PRODUCTION Environment Deployment ⚠️"

################################################################################
# Security Checks
################################################################################

print_header "Security Checks"

# Check for default passwords
if [[ "$DB_PASSWORD" == *"CHANGEME"* ]]; then
    print_error "Default password detected in DB_PASSWORD!"
    print_error "Please update .env file with secure passwords before deploying to production"
    exit 1
fi

if [[ "$DB_ADMIN_PASSWORD" == *"CHANGEME"* ]]; then
    print_error "Default password detected in DB_ADMIN_PASSWORD!"
    print_error "Please update .env file with secure passwords before deploying to production"
    exit 1
fi

print_success "Password security check passed"

################################################################################
# Create Directories
################################################################################

print_header "Creating Directory Structure"
mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/src"
mkdir -p "$SCRIPT_DIR/mongo-init"
print_success "Directories created"

################################################################################
# No SSH Setup for Production
################################################################################

print_header "SSH Configuration"
print_warning "SSH disabled in production environment"
print_warning "Use 'docker compose exec server-container bash' for emergency access only"

# Create placeholder authorized_keys
echo "# SSH not used in production environment" > "$SCRIPT_DIR/../common/authorized_keys"

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
# Clone GitHub Repository (Latest Stable Tag)
################################################################################

print_header "Setting Up Project from GitHub"

GITHUB_REPO_URL=${GITHUB_REPO_URL:-}
GITHUB_TAG=${GITHUB_TAG:-latest}

if [ -n "$GITHUB_REPO_URL" ]; then
    # Remove existing project directory if it exists
    if [ -d "$SCRIPT_DIR/$PROJECT_DIR" ]; then
        print_warning "Removing existing project directory"
        rm -rf "$SCRIPT_DIR/$PROJECT_DIR"
    fi
    
    # Determine which tag to use
    if [ "$GITHUB_TAG" = "latest" ]; then
        print_success "Fetching latest stable tag from $GITHUB_REPO_URL"
        
        # Get the latest tag from GitHub
        LATEST_TAG=$(git ls-remote --tags --sort=v:refname "$GITHUB_REPO_URL" | tail -n1 | sed 's/.*\///' | sed 's/\^{}//')
        
        if [ -z "$LATEST_TAG" ]; then
            print_error "No tags found in repository - cannot deploy to production"
            print_error "Please create a stable version tag (e.g., v1.0.0) before deploying"
            exit 1
        fi
        
        print_success "Latest stable tag: $LATEST_TAG"
        TAG_TO_USE="$LATEST_TAG"
    else
        TAG_TO_USE="$GITHUB_TAG"
        print_success "Using specified tag: $TAG_TO_USE"
    fi
    
    # Clone the repository at the specified tag
    print_success "Cloning repository from $GITHUB_REPO_URL (tag: $TAG_TO_USE)"
    
    if git clone --branch "$TAG_TO_USE" --single-branch "$GITHUB_REPO_URL" "$SCRIPT_DIR/$PROJECT_DIR"; then
        print_success "Repository cloned successfully at tag $TAG_TO_USE"
        
        # Copy VS Code devcontainer configuration
        print_success "Copying VS Code devcontainer configuration"
        mkdir -p "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer"
        cp "$SCRIPT_DIR/../common/.devcontainer/devcontainer.json" \
           "$SCRIPT_DIR/$PROJECT_DIR/.devcontainer/" 2>/dev/null || true
    else
        print_error "Failed to clone repository at tag $TAG_TO_USE - aborting deployment"
        exit 1
    fi
else
    print_warning "No GitHub repository URL specified - verifying existing project"
    
    # Original verification code
    if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/Cargo.toml" ]; then
        print_error "No Cargo.toml found and no repository URL specified"
        print_error "Either set GITHUB_REPO_URL in .env or provide a valid project"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/src/main.rs" ]; then
        print_error "No main.rs found - invalid project structure"
        exit 1
    fi
    
    print_success "Existing project verified"
fi

################################################################################
# Build and Deploy
################################################################################

print_header "Building Docker Images"
docker compose -f docker-compose-prod.yml build
print_success "Images built"

print_header "Starting Production Services"
docker compose -f docker-compose-prod.yml up -d
print_success "Services started"

sleep 3

################################################################################
# Display Status
################################################################################

print_header "Deployment Complete - PRODUCTION Environment"
docker compose -f docker-compose-prod.yml ps

echo ""
print_success "Production environment is running!"
echo ""
echo "Service URLs (Internal):"
echo "  - Application:       http://localhost:${APP_PORT:-5666}"
echo ""
echo "External Access:"
echo "  - Application:       ${EXTERNAL_URL:-https://set.domain.synology.me}"
echo ""
echo "Configuration:"
echo "  - Environment:       PRODUCTION"
echo "  - Container:         ${CONTAINER_NAME:-server-container}"
echo "  - Project Dir:       $PROJECT_DIR"
echo "  - Database:          $DB_NAME"
echo "  - Mongo Express:     DISABLED (production)"
echo "  - SSH Access:        DISABLED (production)"
echo ""
echo "Synology Reverse Proxy Setup:"
echo "  1. Go to: Control Panel -> Application Portal -> Reverse Proxy"
echo "  2. Click 'Create'"
echo "  3. Configure:"
echo "     Description:      SET Game Production"
echo "     Source:"
echo "       Protocol:       HTTPS"
echo "       Hostname:       set.domain.synology.me"
echo "       Port:           443"
echo "     Destination:"
echo "       Protocol:       HTTP"
echo "       Hostname:       localhost"
echo "       Port:           ${APP_PORT:-5666}"
echo "  4. Enable HSTS and HTTP/2"
echo "  5. Configure SSL certificate (Let's Encrypt)"
echo ""
echo "Useful Commands:"
echo "  - Logs:      docker compose -f docker-compose-prod.yml logs -f"
echo "  - Stop:      docker compose -f docker-compose-prod.yml down"
echo "  - Restart:   docker compose -f docker-compose-prod.yml restart"
echo "  - Shell:     docker compose -f docker-compose-prod.yml exec server-container bash"
echo ""
echo "Security Reminders:"
echo "  - Monitor logs regularly"
echo "  - Keep backups of MongoDB data"
echo "  - Review and rotate passwords periodically"
echo "  - Monitor resource usage on Synology NAS"
echo ""
