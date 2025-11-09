################################################################################
# Rust Development Environment - Version 0.4
# Master Deployment Script (PowerShell)
#
# This script orchestrates deployment to different environments using
# environment-specific configuration files.
#
# Usage:
#   .\deploy-v04.ps1 --dev      # Deploy development environment
#   .\deploy-v04.ps1 --test     # Deploy test environment (Synology NAS)
#   .\deploy-v04.ps1 --prod     # Deploy production environment (Synology NAS)
#
# Each environment has its own:
#   - .env file with environment-specific configuration
#   - docker-compose file optimized for that environment
#   - deployment script with environment-specific logic
################################################################################

param(
    [Parameter(Position=0)]
    [string]$Environment
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Show-Usage {
    Write-Host "Usage: .\deploy-v04.ps1 [--dev|--test|--prod]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --dev       Deploy development environment (local laptop)"
    Write-Host "  --test      Deploy test environment (Synology NAS)"
    Write-Host "  --prod      Deploy production environment (Synology NAS)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy-v04.ps1 --dev       # Deploy to local development laptop"
    Write-Host "  .\deploy-v04.ps1 --test      # Deploy to Synology NAS (test)"
    Write-Host "  .\deploy-v04.ps1 --prod      # Deploy to Synology NAS (production)"
    Write-Host ""
}

################################################################################
# Main Script
################################################################################

Write-Header "Rust Development Environment v0.4 - Deployment"

# Parse command line arguments
if (-not $Environment) {
    Write-Error-Custom "No environment specified"
    Show-Usage
    exit 1
}

$EnvName = ""
$EnvDir = ""

switch ($Environment) {
    "--dev" {
        $EnvName = "dev"
        $EnvDir = Join-Path $ScriptDir "dev"
        Write-Success "Selected: Development Environment"
    }
    "--test" {
        $EnvName = "test"
        $EnvDir = Join-Path $ScriptDir "test"
        Write-Success "Selected: Test Environment (Synology NAS)"
    }
    "--prod" {
        $EnvName = "prod"
        $EnvDir = Join-Path $ScriptDir "prod"
        Write-Success "Selected: Production Environment (Synology NAS)"
    }
    { $_ -in @("-h", "--help") } {
        Show-Usage
        exit 0
    }
    default {
        Write-Error-Custom "Invalid option: $Environment"
        Show-Usage
        exit 1
    }
}

# Verify environment directory exists
if (-not (Test-Path $EnvDir)) {
    Write-Error-Custom "Environment directory not found: $EnvDir"
    exit 1
}

# Check for required files
$DeployScript = Join-Path $EnvDir "deploy-$EnvName.ps1"
if (-not (Test-Path $DeployScript)) {
    Write-Error-Custom "Deployment script not found: $DeployScript"
    exit 1
}

# Display environment information
Write-Header "Deployment Configuration"
Write-Host "Environment:     $EnvName"
Write-Host "Directory:       $EnvDir"
Write-Host "Deploy Script:   $DeployScript"
Write-Host ""

# Confirm deployment (skip for dev)
if ($EnvName -ne "dev") {
    Write-Info "You are about to deploy to $EnvName environment"
    $confirm = Read-Host "Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Error-Custom "Deployment cancelled"
        exit 0
    }
}

# Execute environment-specific deployment script
Write-Header "Executing $EnvName Deployment"
Set-Location $EnvDir
& $DeployScript

Write-Success "Deployment to $EnvName environment completed!"
