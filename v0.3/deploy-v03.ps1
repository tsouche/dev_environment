################################################################################
# Rust Development Environment Deployment Script - Version 0.3 (PowerShell)
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
# Usage: .\deploy-v03.ps1
################################################################################

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectName = "rust-dev-environment-v03"
$Dockerfile = "dockerfile.v0.2"
$ComposeFile = "docker-compose-v03.yml"

# Load .env file if it exists
$EnvFile = Join-Path $ScriptDir ".env"
if (Test-Path $EnvFile) {
    Write-Success ".env file found - loading configuration"
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
} else {
    Write-Warning "No .env file found - using defaults from .env.example"
}

# Set defaults if not in .env
$ProjectDir = if ($env:PROJECT_DIR) { $env:PROJECT_DIR } else { "rust_project" }
$DbName = if ($env:DB_NAME) { $env:DB_NAME } else { "rust_app_db" }
$DbUser = if ($env:DB_USER) { $env:DB_USER } else { "app_user" }
$DbPassword = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "app_password" }
$Collection1 = if ($env:COLLECTION_1) { $env:COLLECTION_1 } else { "items" }
$Collection2 = if ($env:COLLECTION_2) { $env:COLLECTION_2 } else { "users" }
$Collection3 = if ($env:COLLECTION_3) { $env:COLLECTION_3 } else { "data" }
$SshPort = if ($env:SSH_PORT) { $env:SSH_PORT } else { "2222" }
$AppPort = if ($env:APP_PORT) { $env:APP_PORT } else { "8080" }
$MongoPort = if ($env:MONGO_PORT) { $env:MONGO_PORT } else { "27017" }
$MongoExpressPort = if ($env:MONGO_EXPRESS_PORT) { $env:MONGO_EXPRESS_PORT } else { "8081" }
$MongoExpressUser = if ($env:MONGO_EXPRESS_USER) { $env:MONGO_EXPRESS_USER } else { "dev" }
$Username = if ($env:USERNAME) { $env:USERNAME } else { "rustdev" }

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
    "$ScriptDir\$ProjectDir\src",
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

$mongoInitScript = @"
// MongoDB initialization script for Rust application database
// This script creates the application user and database
// Configuration is loaded from environment variables

db = db.getSiblingDB('$DbName');

// Create application user with read/write permissions
db.createUser({
    user: '$DbUser',
    pwd: '$DbPassword',
    roles: [
        {
            role: 'readWrite',
            db: '$DbName'
        }
    ]
});

// Create initial collections (examples - customize for your project)
db.createCollection('$Collection1');
db.createCollection('$Collection2');
db.createCollection('$Collection3');

print('Database initialized successfully');
print('Database: $DbName');
print('User: $DbUser');
print('Collections: $Collection1, $Collection2, $Collection3');
"@

$mongoInitScript | Out-File -FilePath "$ScriptDir\docker\mongo-init\01-init-db.js" -Encoding UTF8

Write-Success "Created MongoDB initialization script"

################################################################################
# Create Sample Rust Project
################################################################################

Write-Header "Creating Sample Rust Project Structure"

# Create Cargo.toml if it doesn't exist
$cargoTomlPath = "$ScriptDir\$ProjectDir\Cargo.toml"
if (-not (Test-Path $cargoTomlPath)) {
    $cargoToml = @"
[package]
name = "$($ProjectName -replace '-','_')"
version = "0.1.0"
edition = "2021"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
"@
    $cargoToml | Out-File -FilePath $cargoTomlPath -Encoding UTF8
    Write-Success "Created Cargo.toml"
} else {
    Write-Success "Cargo.toml already exists"
}

# Create main.rs if it doesn't exist
$mainRsPath = "$ScriptDir\$ProjectDir\src\main.rs"
if (-not (Test-Path $mainRsPath)) {
    $mainRs = @'
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
'@
    $mainRs | Out-File -FilePath $mainRsPath -Encoding UTF8
    Write-Success "Created src/main.rs"
} else {
    Write-Success "src/main.rs already exists"
}

################################################################################
# Fix docker-compose-v03.yml
################################################################################

Write-Header "Verifying Docker Compose Configuration"

# Read docker-compose-v03.yml content
$composeContent = Get-Content "$ScriptDir\$ComposeFile" -Raw

# Check if Dockerfile name needs to be updated
if ($composeContent -match "dockerfile: Dockerfile\s") {
    Write-Warning "Updating Dockerfile reference in docker-compose-v03.yml"
    $composeContent = $composeContent -replace "dockerfile: Dockerfile", "dockerfile: $Dockerfile"
    $composeContent | Out-File -FilePath "$ScriptDir\$ComposeFile" -Encoding UTF8
    Write-Success "Updated docker-compose-v03.yml"
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
Write-Host "  - SSH Access:        localhost:$SshPort (user: $Username)"
Write-Host "  - Application:       http://localhost:$AppPort"
Write-Host "  - MongoDB:           localhost:$MongoPort"
Write-Host "  - Mongo Express:     http://localhost:$MongoExpressPort (user: $MongoExpressUser)"
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  - Project Directory: $ProjectDir"
Write-Host "  - Database Name:     $DbName"
Write-Host "  - Database User:     $DbUser"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Blue
Write-Host "  1. Configure VS Code Remote-SSH to connect to localhost:$SshPort"
Write-Host "  2. Connect to 'rust-dev' container via VS Code"
Write-Host "  3. Open /workspace/$ProjectDir in VS Code"
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
    Port $SshPort
    User $Username
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
Write-Host "4. Open folder: /workspace/$ProjectDir"
Write-Host ""

Write-Success "Deployment complete!"
