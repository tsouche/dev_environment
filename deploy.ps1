################################################################################
# Rust Development Environment - Master Deployment Script (PowerShell)
#
# This script automatically deploys the latest version of the environment.
# Currently: v0.4
#
# Usage:
#   .\deploy.ps1 --dev      # Deploy development environment
#   .\deploy.ps1 --test     # Deploy test environment (Synology NAS)
#   .\deploy.ps1 --prod     # Deploy production environment (Synology NAS)
################################################################################

param(
    [Parameter(Position=0)]
    [string]$Environment
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script directory (root of env_builder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Latest version
$LatestVersion = "v0.4"

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

function Show-Usage {
    Write-Host "Usage: .\deploy.ps1 [--dev|--test|--prod]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --dev       Deploy development environment (local laptop)"
    Write-Host "  --test      Deploy test environment (Synology NAS)"
    Write-Host "  --prod      Deploy production environment (Synology NAS)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 --dev       # Deploy to local development laptop"
    Write-Host "  .\deploy.ps1 --test      # Deploy to Synology NAS (test)"
    Write-Host "  .\deploy.ps1 --prod      # Deploy to Synology NAS (production)"
    Write-Host ""
    Write-Host "Current version: $LatestVersion"
    Write-Host ""
}

################################################################################
# Main Script
################################################################################

Write-Header "Rust Development Environment - Master Deployment"

# Check if no arguments provided
if (-not $Environment) {
    Write-Error-Custom "No environment specified"
    Show-Usage
    exit 1
}

# Show help
if ($Environment -in @("-h", "--help")) {
    Show-Usage
    exit 0
}

# Validate environment argument
if ($Environment -notin @("--dev", "--test", "--prod")) {
    Write-Error-Custom "Invalid option: $Environment"
    Show-Usage
    exit 1
}

# Display version information
Write-Success "Using latest version: $LatestVersion"
Write-Host ""

# Construct path to version-specific deployment script
$VersionScript = Join-Path $ScriptDir "$LatestVersion\deploy-v04.ps1"

# Verify version script exists
if (-not (Test-Path $VersionScript)) {
    Write-Error-Custom "Version deployment script not found: $VersionScript"
    Write-Host "Please ensure $LatestVersion directory exists and contains the deployment script."
    exit 1
}

# Store current directory
$OriginalDir = Get-Location

# Execute version-specific deployment script
Write-Host "Executing: $VersionScript $Environment" -ForegroundColor Cyan
Write-Host ""

try {
    & $VersionScript $Environment
    
    # Ensure we're back in the original directory
    Set-Location $OriginalDir
    
    Write-Host ""
    Write-Success "Deployment completed successfully!"
}
catch {
    Write-Error-Custom "Deployment failed: $_"
    Set-Location $OriginalDir
    exit 1
}
