################################################################################
# Deploy Development Environment - Root Script
# Triggers the v0.5 environment deployment
################################################################################

$ErrorActionPreference = "Stop"

# Path to the v0.5 deployment script
$deployScriptPath = Join-Path $PSScriptRoot "v0.5\env_dev\deploy-dev.ps1"

if (-not (Test-Path $deployScriptPath)) {
    Write-Host "[ERROR] Deployment script not found: $deployScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Triggering v0.5 development environment deployment..." -ForegroundColor Green
Write-Host "Script: $deployScriptPath" -ForegroundColor Gray
Write-Host ""

# Execute the deployment script
& $deployScriptPath