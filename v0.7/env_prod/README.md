# Production Environment Deployment Guide

Complete guide for deploying the backend to Synology NAS production environment with pre-compiled executable.

## Table of Contents
1. [Overview](#overview)
2. [Network Architecture](#network-architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Deployment Scripts](#deployment-scripts)
6. [NAS Configuration](#nas-configuration)
7. [Docker Management](#docker-management)
8. [Services & Access](#services--access)
9. [Monitoring & Health Checks](#monitoring--health-checks)
10. [Troubleshooting](#troubleshooting)
11. [File Structure](#file-structure)

---

## Overview

- **Build Location**: Local development machine (with Rust toolchain)
- **Deployment Target**: Synology DS1821+ NAS (Docker only)
- **Build Type**: Debug or Release executable (x86_64)
- **Services**: Backend + MongoDB (NO Mongo Express in production)
- **Network**: Tailscale VPN for SSH/management, HTTPS for public access

**NAS Details:**
- **Model**: Synology DS1821+ (AMD Ryzen V1500B, x86_64)
- **Public Hostname**: `souchefr.synology.me` (HTTPS only, port 443)
- **Tailscale IP**: `100.100.10.1`
- **SSH Port**: `5522` (Tailscale access only)
- **User**: `thierry` (UID: 1026, GID: 100)

---

## Network Architecture

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│ Development Laptop  │     │   Tailscale      │     │ Synology NAS        │
│ (Rust toolchain)    │────>│   VPN Network    │────>│ 100.100.10.1        │
│                     │     │   100.100.x.x    │     │ Docker Services     │
└─────────────────────┘     └──────────────────┘     └─────────────────────┘
                                                              │
                                                              │ Reverse Proxy
                                                              ↓
                                                      Internet (Port 443)
                                                      set.souchefr.synology.me
```

### Access Patterns

| Component | Access Method | URL/Address |
|-----------|---------------|-------------|
| **SSH** | Tailscale only | `ssh -p 5522 thierry@100.100.10.1` |
| **Backend API** | Public HTTPS | `https://set.souchefr.synology.me` |
| **MongoDB** | Internal (containers) | `mongodb://mongo-db:27017` |

**Important**: SSH is **NOT** accessible via public hostname. Use Tailscale VPN.
**Security**: MongoDB is **NOT** exposed externally - internal network only.

---

## Prerequisites

### 1. Local Development Machine

- Rust toolchain (cargo, rustc)
- SSH client
- **Tailscale installed and connected**
- Cross-compilation target: `rustup target add x86_64-unknown-linux-gnu`

### 2. Synology NAS

- Docker package installed
- Docker Compose installed
- SSH enabled on port 5522
- **Tailscale installed and running**
- **Passwordless sudo configured for Docker** ⚠️ **REQUIRED**
- Storage at `/volume1/docker/setprod/`

### 3. Configuration

Before deployment:
1. **Change passwords in `.env` file** (CRITICAL for production!)
2. Configure reverse proxy in Synology DSM:
   - Source: `set.souchefr.synology.me` (HTTPS, port 443)
   - Destination: `localhost:5646`
3. Ensure MongoDB data directory has proper permissions

---

## Quick Start

### Automated Deployment (Recommended)

The deployment script includes comprehensive pre-checks before deployment:

```bash
# Navigate to production environment
cd src/env_prod

# Deploy everything in one command (requires confirmation)
./full_deploy.sh 100.100.10.1

# For release build (optimized, production-ready)
./full_deploy.sh 100.100.10.1 thierry 5522 --release
```

**Pre-Deployment Checks**:
1. **Tailscale Connectivity**: Verifies VPN network access (warning only)
2. **TCP Port Connectivity**: Tests SSH port accessibility to NAS
3. **Rust Toolchain**: Verifies installation and target (auto-installs if missing)
4. **SSH Passwordless Access**: Tests and auto-configures if needed

**Safety**: Production deployment requires explicit confirmation (`DEPLOY TO PRODUCTION`).

### Manual Step-by-Step (Advanced)

```bash
# 1. Setup SSH access (first time only)
./setup_ssh_access.sh 100.100.10.1 thierry 5522

# 2. Deploy (builds + transfers + deploys)
./full_deploy.sh 100.100.10.1 thierry 5522 --release

# Or SSH to NAS and deploy manually
ssh -p 5522 thierry@100.100.10.1
cd /volume1/docker/setprod/backend
./deploy_nas.sh --detached
```

---

## Deployment Scripts

### `setup_ssh_access.sh`

Configures passwordless SSH access to the NAS (run once).

```bash
./setup_ssh_access.sh <nas_ip> [user] [port]
```

**Actions**:
- Generates SSH key pair if needed
- Copies public key to NAS
- Tests passwordless access
- Configures sudo for Docker commands

### `full_deploy.sh`

Complete automated deployment from local machine.

```bash
./full_deploy.sh 100.100.10.1 thierry 5522 --release
```

**Pre-Deployment Checks**:
1. Tailscale connectivity (warning only if unavailable)
2. TCP port connectivity test to NAS
3. Rust toolchain verification + target installation
4. SSH passwordless access check + auto-setup

**Actions**:
1. Builds executable (x86_64-unknown-linux-gnu target)
2. Transfers files to NAS via SCP
3. Executes remote deployment
4. Verifies service health

**Requires confirmation**: Type `DEPLOY TO PRODUCTION` to proceed.

### `deploy_nas.sh`

Deploys containers on NAS (run this ON the NAS).

```bash
./deploy_nas.sh --detached    # Run in background
./deploy_nas.sh               # Run in foreground (see logs)
```

**Actions**:
1. Verifies required files
2. Stops existing containers
3. Removes old backend container/image
4. Builds new Docker image
5. Starts services (backend + MongoDB)

### `clean.sh`

Stops and removes containers (run ON the NAS).

```bash
./clean.sh                  # Stop containers
./clean.sh --volumes        # Also remove volumes (DATABASE DATA!)
./clean.sh --all            # Remove everything including executable
```

**Warning**: Requires explicit confirmation for production environment.

---

## NAS Configuration

### Directory Structure

```
/volume1/docker/setprod/
└── backend/
    ├── set_backend              # Compiled executable
    ├── Dockerfile               # Container definition
    ├── docker-compose.yml       # Service orchestration
    ├── .env                     # Environment variables
    ├── deploy_nas.sh           # Deployment script
    ├── clean.sh                # Cleanup script
    ├── README.md               # This file
    ├── data/                   # Application data
    └── mongodb/
        ├── data/               # MongoDB database files
        └── init/               # MongoDB init scripts
```

### Passwordless Sudo for Docker

Required for automated deployment. Configure on NAS:

```bash
# Edit sudoers file
sudo visudo

# Add this line (replace 'thierry' with your username):
thierry ALL=(ALL) NOPASSWD: /usr/local/bin/docker, /usr/local/bin/docker-compose
```

### Reverse Proxy Configuration

In Synology DSM → Control Panel → Application Portal → Reverse Proxy:

- **Description**: SET Backend Production
- **Source**:
  - Protocol: `HTTPS`
  - Hostname: `set.souchefr.synology.me`
  - Port: `443`
- **Destination**:
  - Protocol: `HTTP`
  - Hostname: `localhost`
  - Port: `5646`

---

## Docker Management

### View Logs

```bash
# All services
docker-compose -p setprod logs -f

# Specific service
docker-compose -p setprod logs -f backend-container
docker-compose -p setprod logs -f mongo-db
```

### Check Status

```bash
# Container status
docker-compose -p setprod ps

# Health checks
docker inspect setprod-backend --format='{{.State.Health.Status}}'
docker inspect setprod-mongodb --format='{{.State.Health.Status}}'
```

### Restart Services

```bash
# Restart all
docker-compose -p setprod restart

# Restart specific service
docker-compose -p setprod restart backend-container
```

### Update Deployment

```bash
# On local machine
cd src/env_prod
./full_deploy.sh 100.100.10.1 thierry 5522 --release
```

**Note**: Build is integrated into `full_deploy.sh` - no separate build step needed.

---

## Services & Access

### Backend API

- **Public URL**: https://set.souchefr.synology.me
- **Internal Port**: 5646
- **Container**: setprod-backend
- **Health Check**: `GET /version`

### MongoDB

- **Internal Only**: mongo-db:27017
- **Container**: setprod-mongodb
- **Data**: `/volume1/docker/setprod/mongodb/data`
- **Admin User**: Configured in `.env`

### Environment Variables

Key settings in `.env`:

```bash
# Ports
APP_PORT=5646

# URLs
EXTERNAL_URL=https://set.souchefr.synology.me

# Database (CHANGE THESE!)
DB_PASSWORD=ProdSecure789!ChangeThisPassword
DB_ADMIN_PASSWORD=ProdAdmin789!ChangeThisPassword

# Logging
RUST_LOG=info
```

---

## Monitoring & Health Checks

### Docker Health Checks

Both services have health checks configured:

**Backend**:
- Command: `curl -f http://localhost:8080/version`
- Interval: 30s
- Timeout: 10s
- Retries: 3
- Start period: 40s

**MongoDB**:
- Command: `mongosh --eval "db.adminCommand('ping')" --quiet`
- Interval: 30s
- Timeout: 10s
- Retries: 3
- Start period: 40s

**Note**: The `mongosh` command runs inside the MongoDB container (mongo:7.0.15-jammy), which includes the MongoDB Shell. The backend runtime container does NOT include `mongosh`.

### Check Health Status

```bash
# View health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health info
docker inspect setprod-backend | grep -A 10 Health
docker inspect setprod-mongodb | grep -A 10 Health
```

### Log Monitoring

```bash
# Monitor for errors
docker-compose -p setprod logs -f | grep -i error

# Monitor backend
docker logs -f setprod-backend

# Monitor MongoDB
docker logs -f setprod-mongodb
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose -p setprod logs

# Check specific container
docker logs setprod-backend
docker logs setprod-mongodb

# Verify executable architecture
ssh -p 5522 thierry@100.100.10.1
file /volume1/docker/setprod/backend/set_backend
# Should show: ELF 64-bit LSB executable, x86-64
```

### Health Check Failing

```bash
# Test endpoint manually
curl http://100.100.10.1:5646/version

# Check if port is listening
netstat -tlnp | grep 5646

# Restart unhealthy container
docker-compose -p setprod restart backend-container
```

### MongoDB Connection Issues

```bash
# Check MongoDB is running
docker exec -it setprod-mongodb mongosh --eval "db.adminCommand('ping')"

# Verify network
docker network inspect prod-network

# Check MongoDB logs
docker logs setprod-mongodb
```

**Note**: `mongosh` is only available in the MongoDB container, not in the backend container.

### Permission Denied Errors

```bash
# Check file permissions
ls -la /volume1/docker/setprod/backend/

# Fix permissions
sudo chown -R thierry:users /volume1/docker/setprod/backend/
chmod +x /volume1/docker/setprod/backend/*.sh
chmod +x /volume1/docker/setprod/backend/set_backend
```

### Public URL Not Working

1. Check reverse proxy configuration in DSM
2. Verify container is running: `docker ps | grep setprod-backend`
3. Test internal access: `curl http://100.100.10.1:5646/version`
4. Check nginx logs in DSM

---

## File Structure

```
env_prod/
├── .env                      # Production environment variables
├── Dockerfile                # Container build definition (minimal runtime)
├── docker-compose.yml        # Service orchestration
├── setup_ssh_access.sh       # SSH automation (first-time setup)
├── full_deploy.sh            # Complete automated deployment with pre-checks
├── deploy_nas.sh             # Deploy on NAS (remote execution)
├── clean.sh                  # Cleanup script
└── README.md                 # This file

Note: Production uses a minimal runtime container. mongosh is NOT included
      in the backend container (only in the MongoDB container).
```

---

## Security Checklist

- ✅ Change all passwords in `.env` file
- ✅ MongoDB not exposed externally
- ✅ SSH access via Tailscale only
- ✅ HTTPS for public API
- ✅ Restart policy: `always`
- ✅ Health checks configured
- ✅ No Mongo Express in production
- ✅ Proper file permissions

---

## Version Information

- **Environment**: Production
- **Version**: 0.7.0
- **Docker Compose**: 3.8
- **MongoDB**: 7.0.15-jammy
- **Project Name**: setprod
- **Network**: prod-network

---

## Support & Maintenance

### Regular Maintenance

1. Monitor logs regularly
2. Check disk space: `/volume1/docker/setprod/mongodb/data`
3. Review health check status
4. Update dependencies when security patches are released

### Backup Recommendations

```bash
# Backup MongoDB data (manual)
tar -czf mongodb-backup-$(date +%Y%m%d).tar.gz /volume1/docker/setprod/mongodb/data/

# Backup .env file (contains passwords)
cp .env .env.backup
```

### Emergency Rollback

```bash
# Stop current deployment
./clean.sh

# Deploy previous version
# (restore previous executable and redeploy)
```

---

**Remember**: This is PRODUCTION. Test changes in `env_test` environment first!
