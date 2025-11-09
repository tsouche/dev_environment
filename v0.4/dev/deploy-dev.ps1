################################################################################
# Development Environment Deployment Script - v0.4 (PowerShell)
# Deploys to local development laptop
################################################################################

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Load environment variables
$EnvFile = Join-Path $ScriptDir ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$ProjectDir = if ($env:PROJECT_DIR) { $env:PROJECT_DIR } else { "rust_project" }
$DbName = if ($env:DB_NAME) { $env:DB_NAME } else { "rust_app_db" }
$DbUser = if ($env:DB_USER) { $env:DB_USER } else { "app_user" }
$DbPassword = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "app_password" }
$Collection1 = if ($env:COLLECTION_1) { $env:COLLECTION_1 } else { "items" }
$Collection2 = if ($env:COLLECTION_2) { $env:COLLECTION_2 } else { "users" }
$Collection3 = if ($env:COLLECTION_3) { $env:COLLECTION_3 } else { "data" }

Write-Header "Development Environment Deployment"

################################################################################
# Create Directories
################################################################################

Write-Header "Creating Directory Structure"
$directories = @(
    "$ScriptDir\$ProjectDir\src",
    "$ScriptDir\mongo-init"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Success "Directories created"

################################################################################
# SSH Key Setup
################################################################################

Write-Header "Configuring SSH Authentication"

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
    Copy-Item $sshKeySource "$ScriptDir\..\common\authorized_keys" -Force
    Write-Success "Copied SSH public key"
} else {
    Write-Warning-Custom "No SSH key found - creating placeholder"
    "# Add your SSH public key here" | Out-File -FilePath "$ScriptDir\..\common\authorized_keys" -Encoding ASCII
}

################################################################################
# MongoDB Init Script
################################################################################

Write-Header "Creating MongoDB Initialization Script"

$mongoInitScript = @"
db = db.getSiblingDB('$DbName');

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

db.createCollection('$Collection1');
db.createCollection('$Collection2');
db.createCollection('$Collection3');

print('Database initialized: $DbName');
"@

$mongoInitScript | Out-File -FilePath "$ScriptDir\mongo-init\01-init-db.js" -Encoding UTF8
Write-Success "MongoDB init script created"

################################################################################
# Create Sample Project
################################################################################

Write-Header "Creating Sample Rust Project"

$cargoTomlPath = "$ScriptDir\$ProjectDir\Cargo.toml"
if (-not (Test-Path $cargoTomlPath)) {
    $cargoToml = @"
[package]
name = "$($env:PROJECT_NAME -replace '-','_')"
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
    Write-Success "Cargo.toml exists"
}

$mainRsPath = "$ScriptDir\$ProjectDir\src\main.rs"
if (-not (Test-Path $mainRsPath)) {
    $mainRs = @'
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
'@
    $mainRs | Out-File -FilePath $mainRsPath -Encoding UTF8
    Write-Success "Created src/main.rs"
} else {
    Write-Success "src/main.rs exists"
}

################################################################################
# Build and Deploy
################################################################################

Write-Header "Building Docker Images"
docker compose -f docker-compose-dev.yml build
Write-Success "Images built"

Write-Header "Starting Services"
docker compose -f docker-compose-dev.yml up -d
Write-Success "Services started"

Start-Sleep -Seconds 3

################################################################################
# Display Status
################################################################################

Write-Header "Deployment Complete - Development Environment"
docker compose -f docker-compose-dev.yml ps

Write-Host ""
Write-Success "Development environment is ready!"
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Blue
Write-Host "  - SSH Access:        localhost:$($env:SSH_PORT) (user: $($env:USERNAME))"
Write-Host "  - Application:       http://localhost:$($env:APP_PORT)"
Write-Host "  - MongoDB:           localhost:$($env:MONGO_PORT)"
Write-Host "  - Mongo Express:     http://localhost:$($env:MONGO_EXPRESS_PORT)"
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  - Environment:       DEV"
Write-Host "  - Container:         $($env:CONTAINER_NAME)"
Write-Host "  - Project Dir:       $ProjectDir"
Write-Host "  - Database:          $DbName"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Blue
Write-Host "  1. Add this to $env:USERPROFILE\.ssh\config:"
Write-Host ""
Write-Host "     Host rust-dev"
Write-Host "         HostName localhost"
Write-Host "         Port $($env:SSH_PORT)"
Write-Host "         User $($env:USERNAME)"
Write-Host "         StrictHostKeyChecking no"
Write-Host ""
Write-Host "  2. Connect via VS Code Remote-SSH to 'rust-dev'"
Write-Host "  3. Open folder: /workspace/$ProjectDir"
Write-Host "  4. Run: cargo build"
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Blue
Write-Host "  - Logs:      docker compose -f docker-compose-dev.yml logs -f"
Write-Host "  - Stop:      docker compose -f docker-compose-dev.yml down"
Write-Host "  - Restart:   docker compose -f docker-compose-dev.yml restart"
Write-Host "  - Shell:     docker compose -f docker-compose-dev.yml exec dev-container bash"
Write-Host ""
