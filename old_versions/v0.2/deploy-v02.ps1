################################################################################
# Rust Development Environment Deployment Script - Version 0.2 (PowerShell)
# 
# This script automates the deployment of a containerized Rust development
# environment with MongoDB support on Windows 11 using Docker Desktop.
#
# Prerequisites:
# - Docker Desktop installed and running
# - VS Code installed with Remote-SSH extension
# - SSH key generated (id_ed25519.pub)
#
# Usage: .\deploy-v02.ps1
################################################################################

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectName = "rust-dev-environment-v02"
$Dockerfile = "dockerfile.v0.2"
$ComposeFile = "docker-compose-v02.yml"

################################################################################
# Helper Functions
################################################################################

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    if ($exists) {
        Write-Success "$Command is installed"
    } else {
        Write-Error-Custom "$Command is not installed"
    }
    return $exists
}

################################################################################
# Pre-flight Checks
################################################################################

Write-Header "Running Pre-flight Checks"

# Check if Docker is installed
if (-not (Test-Command "docker")) {
    Write-Error-Custom "Docker Desktop is not installed or not in PATH"
    exit 1
}

# Check if Docker daemon is running
try {
    docker info | Out-Null
    Write-Success "Docker Desktop is running"
} catch {
    Write-Error-Custom "Docker Desktop is not running. Please start Docker Desktop and try again."
    exit 1
}

# Check if docker-compose is available
try {
    docker compose version | Out-Null
    Write-Success "Docker Compose is available"
} catch {
    Write-Error-Custom "Docker Compose is not available"
    exit 1
}

################################################################################
# Directory Structure Setup
################################################################################

Write-Header "Setting Up Directory Structure"

# Create required directories
$directories = @(
    "$ScriptDir\set_backend\src",
    "$ScriptDir\docker\mongo-init",
    "$ScriptDir\.ssh"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Success "Created directory structure"

################################################################################
# SSH Key Setup
################################################################################

Write-Header "Configuring SSH Authentication"

# Check for SSH public key
$sshKeySource = $null
$sshKeyPaths = @(
    "$env:USERPROFILE\.ssh\id_ed25519.pub",
    "$env:USERPROFILE\.ssh\id_rsa.pub"
)

foreach ($keyPath in $sshKeyPaths) {
    if (Test-Path $keyPath) {
        $sshKeySource = $keyPath
        break
    }
}

if ($null -ne $sshKeySource) {
    Copy-Item $sshKeySource "$ScriptDir\authorized_keys" -Force
    Write-Success "Copied SSH public key from $sshKeySource"
} else {
    Write-Warning "No SSH public key found. Creating a placeholder file."
    Write-Warning "You'll need to add your SSH public key to 'authorized_keys' file before building."
    "# Add your SSH public key here (id_ed25519.pub or id_rsa.pub)" | Out-File -FilePath "$ScriptDir\authorized_keys" -Encoding ASCII
    Write-Host ""
    Write-Host "To generate an SSH key, run in PowerShell:" -ForegroundColor Yellow
    Write-Host '  ssh-keygen -t ed25519 -C "your_email@example.com"' -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to continue or Ctrl+C to abort"
}

################################################################################
# MongoDB Initialization Script
################################################################################

Write-Header "Creating MongoDB Initialization Script"

$mongoInitScript = @'
// MongoDB initialization script for SET game database
// This script creates the application user and database

db = db.getSiblingDB('set_game_db');

// Create application user with read/write permissions
db.createUser({
    user: 'set_app_user',
    pwd: 'set_app_password',
    roles: [
        {
            role: 'readWrite',
            db: 'set_game_db'
        }
    ]
});

// Create initial collections
db.createCollection('games');
db.createCollection('players');
db.createCollection('scores');

print('Database initialized successfully');
'@

$mongoInitScript | Out-File -FilePath "$ScriptDir\docker\mongo-init\01-init-db.js" -Encoding UTF8

Write-Success "Created MongoDB initialization script"

################################################################################
# Create Sample Rust Project
################################################################################

Write-Header "Creating Sample Rust Project Structure"

# Create Cargo.toml if it doesn't exist
$cargoTomlPath = "$ScriptDir\set_backend\Cargo.toml"
if (-not (Test-Path $cargoTomlPath)) {
    $cargoToml = @'
[package]
name = "set_backend"
version = "0.1.0"
edition = "2021"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
'@
    $cargoToml | Out-File -FilePath $cargoTomlPath -Encoding UTF8
    Write-Success "Created Cargo.toml"
} else {
    Write-Success "Cargo.toml already exists"
}

# Create main.rs if it doesn't exist
$mainRsPath = "$ScriptDir\set_backend\src\main.rs"
if (-not (Test-Path $mainRsPath)) {
    $mainRs = @'
use mongodb::{Client, options::ClientOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("SET Game Backend - Development Environment");
    
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
'@
    $mainRs | Out-File -FilePath $mainRsPath -Encoding UTF8
    Write-Success "Created src/main.rs"
} else {
    Write-Success "src/main.rs already exists"
}

################################################################################
# Fix docker-compose-v02.yml
################################################################################

Write-Header "Verifying Docker Compose Configuration"

# Read docker-compose-v02.yml content
$composeContent = Get-Content "$ScriptDir\$ComposeFile" -Raw

# Check if Dockerfile name needs to be updated
if ($composeContent -match "dockerfile: Dockerfile\s") {
    Write-Warning "Updating Dockerfile reference in docker-compose-v02.yml"
    $composeContent = $composeContent -replace "dockerfile: Dockerfile", "dockerfile: $Dockerfile"
    $composeContent | Out-File -FilePath "$ScriptDir\$ComposeFile" -Encoding UTF8
    Write-Success "Updated docker-compose-v02.yml"
}

################################################################################
# Build and Deploy
################################################################################

Write-Header "Building Docker Images"

Set-Location $ScriptDir

# Build the development container
docker compose build

Write-Success "Docker images built successfully"

################################################################################
# Start Services
################################################################################

Write-Header "Starting Services"

# Start all services in detached mode
docker compose up -d

Write-Success "Services started successfully"

# Wait for services to be ready
Write-Host ""
Write-Host "Waiting for services to be ready..."
Start-Sleep -Seconds 5

################################################################################
# Display Status
################################################################################

Write-Header "Deployment Summary"

# Show running containers
docker compose ps

Write-Host ""
Write-Success "Development environment deployed successfully!"
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Blue
Write-Host "  - SSH Access:        localhost:2222 (user: rustdev)"
Write-Host "  - Application:       http://localhost:8080"
Write-Host "  - MongoDB:           localhost:27017"
Write-Host "  - Mongo Express:     http://localhost:8081 (user: dev, pass: dev123)"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Blue
Write-Host "  1. Configure VS Code Remote-SSH to connect to localhost:2222"
Write-Host "  2. Connect to 'rust-dev' container via VS Code"
Write-Host "  3. Open /workspace/set_backend in VS Code"
Write-Host "  4. Run 'cargo build' to verify setup"
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Blue
Write-Host "  - View logs:         docker compose logs -f"
Write-Host "  - Stop services:     docker compose down"
Write-Host "  - Restart services:  docker compose restart"
Write-Host "  - Shell access:      docker compose exec rust-dev bash"
Write-Host ""

################################################################################
# VS Code SSH Configuration Helper
################################################################################

Write-Header "VS Code SSH Configuration"

$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$sshConfigContent = @"

Host rust-dev-container
    HostName localhost
    Port 2222
    User rustdev
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@

Write-Host "Add this to your VS Code SSH config file ($sshConfigPath):" -ForegroundColor Cyan
Write-Host $sshConfigContent

Write-Host ""
Write-Host "Then in VS Code:" -ForegroundColor Cyan
Write-Host "1. Press Ctrl+Shift+P"
Write-Host "2. Type 'Remote-SSH: Connect to Host'"
Write-Host "3. Select 'rust-dev-container'"
Write-Host "4. Open folder: /workspace/set_backend"
Write-Host ""

Write-Success "Deployment complete!"
