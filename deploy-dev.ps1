################################################################################
# Deploy Development Environment - Root Script
# Triggers the v0.5 environment deployment
################################################################################

$ErrorActionPreference = "Stop"

# Path to the v0.5 env_dev directory
$envDevDir = Join-Path $PSScriptRoot "v0.5\env_dev"
$deployScriptPath = Join-Path $envDevDir "deploy-dev.ps1"

if (-not (Test-Path $deployScriptPath)) {
    Write-Host "[ERROR] Deployment script not found: $deployScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Triggering v0.5 development environment deployment..." -ForegroundColor Green
Write-Host "Script: $deployScriptPath" -ForegroundColor Gray
Write-Host ""

# Change to the env_dev directory and execute the deployment script
Push-Location $envDevDir
try {
    & ".\deploy-dev.ps1"
} finally {
    Pop-Location
}