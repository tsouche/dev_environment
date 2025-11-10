# Test Environment Deployment Guide

Complete guide for deploying and testing the backend on Synology NAS with pre-compiled executable.

## Table of Contents
1. [Overview](#overview)
2. [Network Architecture](#network-architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Deployment Scripts](#deployment-scripts)
6. [NAS Configuration](#nas-configuration)
7. [Docker Management](#docker-management)
8. [Services & Access](#services--access)
9. [Troubleshooting](#troubleshooting)
10. [File Structure](#file-structure)

---

## Overview

- **Build Location**: Local development machine (with Rust toolchain)
- **Deployment Target**: Synology DS1821+ NAS (Docker only)
- **Build Type**: Debug executable with symbols (x86_64)
- **Services**: Backend + MongoDB + Mongo Express
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
                                                      settest.souchefr.synology.me
```

### Access Patterns

| Component | Access Method | URL/Address |
|-----------|---------------|-------------|
| **SSH** | Tailscale only | `ssh -p 5522 thierry@100.100.10.1` |
| **Backend API** | Public HTTPS | `https://settest.souchefr.synology.me` |
| **Mongo Express** | Tailscale only | `http://100.100.10.1:8081` |
| **MongoDB** | Internal (containers) | `mongodb://mongodb:27017` |

**Important**: SSH and Mongo Express are **NOT** accessible via public hostname. Use Tailscale VPN.

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
- Storage at `/volume1/docker/settest/`

### 3. Configure Passwordless Sudo for Docker

Docker on Synology requires sudo even for administrators. Configure passwordless access:

```bash
# SSH to NAS
ssh -p 5522 thierry@100.100.10.1

# Edit sudoers safely
sudo visudo

# Add these lines at the END:
thierry ALL=(ALL) NOPASSWD: /usr/local/bin/docker
thierry ALL=(ALL) NOPASSWD: /usr/local/bin/docker-compose
thierry ALL=(ALL) NOPASSWD: /usr/bin/docker
thierry ALL=(ALL) NOPASSWD: /usr/bin/docker-compose

# Save: Ctrl+X, Y, Enter (nano) or :wq (vi)
```

**Verify:**
```bash
sudo docker ps  # Should NOT ask for password
```

**Why?** Synology DSM's Docker socket permissions require elevated privileges. The deployment scripts automatically use `sudo` when needed.

### 4. Verify Tailscale Connectivity

```bash
# Check Tailscale status
tailscale status

# Verify NAS is accessible
ping 100.100.10.1

# Test SSH connection
ssh -p 5522 thierry@100.100.10.1 "echo 'Connected!'"
```

### 5. VS Code Remote SSH (Optional)

Add to `~/.ssh/config`:

```ssh-config
Host synology-nas
    HostName 100.100.10.1
    User thierry
    Port 5522
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes
```

Connect: **Remote-SSH: Connect to Host** → `synology-nas`

---

## Quick Start

### Option A: Full Automation (Recommended)

Single command deployment:

```bash
cd /workspace/set_backend/src/env_test
./full_deploy.sh 100.100.10.1 thierry 5522 --release
```

This will:
1. Build the x86_64 executable
2. Transfer files to NAS via Tailscale
3. Deploy on NAS with Docker Compose

### Option B: Step-by-Step

**1. Build executable:**
```bash
cd /workspace/set_backend/src/env_test
./build_and_collect.sh --release
```

**2. Transfer to NAS:**
```bash
./transfer_to_nas.sh 100.100.10.1 thierry 5522
```

**3. Deploy on NAS:**
```bash
ssh -p 5522 thierry@100.100.10.1
cd /volume1/docker/settest/backend
./deploy_nas.sh --detached
```

### Option C: Manual Transfer

```bash
# 1. Build
cd /workspace/set_backend/src/env_test
./build_and_collect.sh

# 2. Manual SCP
scp -P 5522 set_backend Dockerfile docker-compose.yml .env deploy_nas.sh clean.sh \
    thierry@100.100.10.1:/volume1/docker/settest/backend/

# 3. Deploy
ssh -p 5522 thierry@100.100.10.1
cd /volume1/docker/settest/backend
chmod +x *.sh set_backend
./deploy_nas.sh --detached
```

---

## Deployment Scripts

### Local Machine Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `build_and_collect.sh` | Build x86_64 executable | `./build_and_collect.sh [--release] [--clean]` |
| `transfer_to_nas.sh` | Transfer files via SCP | `./transfer_to_nas.sh <nas_ip> [user] [port]` |
| `full_deploy.sh` | Complete automation | `./full_deploy.sh <nas_ip> [user] [port] [--release]` |

**Examples:**
```bash
# Build debug version
./build_and_collect.sh

# Build release version
./build_and_collect.sh --release

# Transfer files
./transfer_to_nas.sh 100.100.10.1 thierry 5522

# Full deployment
./full_deploy.sh 100.100.10.1 thierry 5522 --release
```

### NAS Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy_nas.sh` | Deploy containers | `./deploy_nas.sh [--detached]` |
| `clean.sh` | Stop and cleanup | `./clean.sh [--volumes] [--all]` |

**Examples:**
```bash
# Deploy (foreground - see logs)
./deploy_nas.sh

# Deploy (detached - background)
./deploy_nas.sh --detached

# Stop containers
./clean.sh

# Stop and remove volumes (database)
./clean.sh --volumes

# Stop and remove everything
./clean.sh --all
```

**Note**: Scripts automatically use `sudo` when needed - no manual intervention required!

---

## NAS Configuration

### Directory Structure on NAS

```
/volume1/docker/settest/
├── backend/
│   ├── set_backend              # Executable
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .env
│   ├── deploy_nas.sh
│   └── clean.sh
├── mongodb/
│   ├── data/                    # Persistent database
│   └── init/                    # Init scripts
```

### Environment Variables

Edit `.env` (v0.5) to customize:

```properties
# NAS Configuration
NAS_TAILSCALE_IP=100.100.10.1
NAS_SSH_PORT=5522
EXTERNAL_URL=https://settest.souchefr.synology.me

# Ports
APP_PORT=5645
MONGO_EXPRESS_PORT=8081

# User/Group
USER_UID=1026
USER_GID=100
USERNAME=thierry

# Database
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=test123
MONGO_DB_NAME=settest

# Mongo Express
ME_CONFIG_BASICAUTH_USERNAME=test
ME_CONFIG_BASICAUTH_PASSWORD=test456

# Paths
PROJECT_PATH=/volume1/docker/settest/backend
VOLUME_MONGODB_DATA=/volume1/docker/settest/mongodb/data
VOLUME_MONGODB_INIT=/volume1/docker/settest/mongodb/init
```

### Build Target

The NAS requires x86_64 binaries:

```bash
# Add target (one-time setup)
rustup target add x86_64-unknown-linux-gnu

# Build manually
cargo build --target x86_64-unknown-linux-gnu --release

# Verify architecture
file target/x86_64-unknown-linux-gnu/release/set_backend
# Should show: ELF 64-bit LSB executable, x86-64
```

---

## Docker Management

### On NAS

```bash
# SSH to NAS
ssh -p 5522 thierry@100.100.10.1
cd /volume1/docker/settest/backend

# View logs (all services)
sudo docker-compose logs -f

# View logs (backend only)
sudo docker-compose logs -f backend

# Check status
sudo docker-compose ps

# Restart services
sudo docker-compose restart

# Restart backend only
sudo docker-compose restart backend

# Stop services
./clean.sh
```

### Using SCP/Rsync

```bash
# SCP single file (capital -P for port)
scp -P 5522 file.txt thierry@100.100.10.1:/volume1/docker/settest/backend/

# Rsync directory (lowercase -p in ssh command)
rsync -avz --progress -e "ssh -p 5522" \
    ./src/env_test/ thierry@100.100.10.1:/volume1/docker/settest/backend/
```

---

## Services & Access

### Service Ports

| Service | Port | Internal | External |
|---------|------|----------|----------|
| Backend | 5645 | `localhost:5645` | `https://settest.souchefr.synology.me` |
| MongoDB | 27017 | `mongodb:27017` | Not exposed |
| Mongo Express | 8081 | `localhost:8081` | `http://100.100.10.1:8081` (Tailscale) |

### Access from Dev Machine

```bash
# Backend API (public - anyone can access)
curl https://settest.souchefr.synology.me/health

# Mongo Express (Tailscale required)
open http://100.100.10.1:8081
# Login: test / test456
```

### Access from NAS

```bash
# SSH to NAS first
ssh -p 5522 thierry@100.100.10.1

# Test backend locally
curl http://localhost:5645/health

# Test Mongo Express
curl http://localhost:8081
```

### MongoDB Connection

From within containers:
```
mongodb://root:test123@mongodb:27017/settest
```

---

## Troubleshooting

### Cannot SSH to NAS

**Problem**: `ssh -p 5522 thierry@souchefr.synology.me` times out

**Solution**: Use Tailscale IP, not public hostname
```bash
# ❌ Wrong - public hostname doesn't allow SSH
ssh -p 5522 thierry@souchefr.synology.me

# ✅ Correct - use Tailscale IP
ssh -p 5522 thierry@100.100.10.1

# Check Tailscale
tailscale status
ping 100.100.10.1
```

### Cannot Access Mongo Express

**Problem**: `http://100.100.10.1:8081` doesn't load

**Solution**: 
1. Verify Tailscale is connected: `tailscale status`
2. Check containers: `sudo docker-compose ps`
3. Check port mapping in `docker-compose.yml`
4. Mongo Express is **NOT** accessible via public hostname

### Docker Permission Denied

**Problem**: 
```bash
docker ps
# permission denied while trying to connect to the Docker daemon socket
```

**Solution**: Configure passwordless sudo (see Prerequisites section)

**Quick fix**:
```bash
ssh -p 5522 thierry@100.100.10.1
sudo visudo
# Add: thierry ALL=(ALL) NOPASSWD: /usr/local/bin/docker, /usr/local/bin/docker-compose, /usr/bin/docker, /usr/bin/docker-compose
```

Verify: `sudo docker ps` (should not ask password)

### Build Fails - Wrong Architecture

**Problem**: Binary won't run on NAS

**Solution**: Ensure correct target
```bash
# Check target is installed
rustup target list | grep x86_64-unknown-linux-gnu

# Build with correct target
cargo build --target x86_64-unknown-linux-gnu --release

# Verify
file target/x86_64-unknown-linux-gnu/release/set_backend
# Must show: ELF 64-bit LSB executable, x86-64
```

### SCP/Rsync Connection Issues

Always use Tailscale IP:
```bash
# ✅ Correct
scp -P 5522 file thierry@100.100.10.1:/path/
rsync -e "ssh -p 5522" file thierry@100.100.10.1:/path/

# ❌ Wrong - will timeout
scp -P 5522 file thierry@souchefr.synology.me:/path/
```

**Note**: `-P` (capital) for SCP, `-p` (lowercase) for SSH/rsync

### Permission Issues on NAS

```bash
# Fix ownership
ssh -p 5522 thierry@100.100.10.1
sudo chown -R thierry:users /volume1/docker/settest
sudo chmod -R 755 /volume1/docker/settest

# Fix executable permissions
chmod +x /volume1/docker/settest/backend/*.sh
chmod +x /volume1/docker/settest/backend/set_backend
```

### Backend Not Accessible Publicly

The backend is only accessible via:
1. **Public HTTPS**: `https://settest.souchefr.synology.me` (reverse proxy)
2. **Localhost**: `http://localhost:5645` (from NAS)

Direct port access `http://souchefr.synology.me:5645` is **NOT available** - only port 443 exposed.

---

## File Structure

### Local Workspace

```
/workspace/set_backend/src/env_test/
├── .env                       # Environment configuration (v0.5)
├── Dockerfile                 # Runtime container (no build tools)
├── docker-compose.yml         # Multi-container orchestration
│
├── build_and_collect.sh       # [LOCAL] Build x86_64 executable
├── transfer_to_nas.sh         # [LOCAL] Transfer files to NAS
├── full_deploy.sh             # [LOCAL] Complete automation
│
├── deploy_nas.sh              # [NAS] Deploy on Synology
├── clean.sh                   # [NAS] Cleanup script
│
├── README.md                  # This complete guide
│
└── set_backend                # [GENERATED] Compiled executable
```

### On Synology NAS

```
/volume1/docker/settest/
├── backend/
│   ├── set_backend           # Executable (transferred)
│   ├── Dockerfile            # Container definition
│   ├── docker-compose.yml    # Service orchestration
│   ├── .env                  # Configuration
│   ├── deploy_nas.sh         # Deployment script
│   └── clean.sh              # Cleanup script
│
└── mongodb/
    ├── data/                 # Persistent database storage
    └── init/                 # Initialization scripts
```

---

## Quick Reference

### Common Commands

```bash
# === LOCAL MACHINE ===

# Full deployment (recommended)
./full_deploy.sh 100.100.10.1 thierry 5522 --release

# Build only
./build_and_collect.sh --release

# Transfer only
./transfer_to_nas.sh 100.100.10.1 thierry 5522

# === ON NAS ===

# SSH to NAS
ssh -p 5522 thierry@100.100.10.1

# Deploy
cd /volume1/docker/settest/backend
./deploy_nas.sh --detached

# View logs
sudo docker-compose logs -f backend

# Check status
sudo docker-compose ps

# Stop services
./clean.sh

# === ACCESS ===

# Backend (public)
https://settest.souchefr.synology.me

# Mongo Express (Tailscale)
http://100.100.10.1:8081
```

### Environment Summary

- **Local**: Build machine with Rust toolchain
- **Transport**: Tailscale VPN (100.100.10.1:5522)
- **Target**: Synology DS1821+ (x86_64, Docker only)
- **Access**: HTTPS public, SSH/Mongo via Tailscale
- **Version**: .env v0.5

---

## Notes

- ⚠️ **Always build with x86_64 target** for NAS compatibility
- ⚠️ **Passwordless sudo required** for Docker on Synology
- ⚠️ **SSH/Mongo Express via Tailscale only** - not public
- 📝 Debug builds provide better error messages and symbols
- 💾 MongoDB data persists across container restarts
- 🔐 Synology UID/GID (1026/100) configured for permissions
- 🚀 Scripts auto-detect and use `sudo` when needed
