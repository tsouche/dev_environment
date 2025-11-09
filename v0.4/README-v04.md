# Rust Development Environment - Version 0.4

**Multi-Environment Deployment Platform for Rust Applications with MongoDB**

> **Version:** 0.4  
> **Last Updated:** November 2025  
> **Key Feature:** Separate configuration files for dev, test, and production environments

---

## 🎯 Overview

Version 0.4 introduces a **simplified multi-environment architecture** with dedicated configuration sets for each deployment target. Instead of complex conditional logic, each environment has its own complete set of files:

- **Development (dev/)**: Local laptop with SSH access and full debugging tools
- **Test (test/)**: Synology NAS with backend container and debugging tools
- **Production (prod/)**: Synology NAS with server container (no debugging tools)

### What's New in v0.4

✨ **Environment Separation** - Dedicated folders for dev, test, prod  
✨ **Simplified Deployment** - Single master script: `./deploy-v04.sh --dev|--test|--prod`  
✨ **No Conditional Logic** - Each environment has its own docker-compose file  
✨ **Clear Security Boundaries** - SSH and debugging tools only where appropriate  
✨ **Production Safety** - Password validation and confirmation prompts

---

## 📁 Project Structure

```
v0.4/
├── deploy-v04.sh              # Master deployment script (Bash)
├── deploy-v04.ps1             # Master deployment script (PowerShell)
├── common/
│   └── dockerfile.v0.4        # Shared Dockerfile for all environments
├── dev/
│   ├── .env                   # Development configuration
│   ├── docker-compose-dev.yml # Development services
│   ├── deploy-dev.sh          # Dev deployment script
│   └── deploy-dev.ps1         # Dev deployment script (PS)
├── test/
│   ├── .env                   # Test configuration
│   ├── docker-compose-test.yml# Test services
│   └── deploy-test.sh         # Test deployment script
└── prod/
    ├── .env                   # Production configuration
    ├── docker-compose-prod.yml# Production services
    └── deploy-prod.sh         # Production deployment script
```

---

## 🚀 Quick Start

### Development Environment (Local Laptop)

```bash
cd v0.4
./deploy-v04.sh --dev
```

**What you get:**
- SSH access on port 2222 (for VS Code Remote)
- Application on http://localhost:5665
- MongoDB on localhost:27017
- Mongo Express on http://localhost:8080

### Test Environment (Synology NAS)

```bash
cd v0.4
./deploy-v04.sh --test
```

**What you get:**
- Backend container (no SSH)
- Application on http://localhost:5665 → https://test_set.domain.synology.me
- MongoDB (internal only)
- Mongo Express on http://localhost:8080

### Production Environment (Synology NAS)

```bash
cd v0.4
./deploy-v04.sh --prod
```

**What you get:**
- Server container (no SSH)
- Application on http://localhost:5666 → https://set.domain.synology.me
- MongoDB (internal only, not exposed to host)
- **NO** Mongo Express (security)

---

## 🏗️ Environment Details

### 1. Development Environment

**Target:** Local development laptop  
**Container Name:** `dev-container`  
**Purpose:** Code development and debugging

#### Features:
- ✅ SSH access on port 2222
- ✅ VS Code Remote-SSH support
- ✅ Mongo Express debugging tool
- ✅ Hot-reload development workflow
- ✅ Full logging (RUST_LOG=debug)

#### Ports:
| Service | Port | Access |
|---------|------|--------|
| SSH | 2222 | VS Code Remote-SSH |
| Application | 5665 | http://localhost:5665 |
| MongoDB | 27017 | localhost:27017 |
| Mongo Express | 8080 | http://localhost:8080 |

#### Deployment:

```bash
# From v0.4 directory
./deploy-v04.sh --dev

# Or directly
cd dev
./deploy-dev.sh
```

#### VS Code Setup:

Add to `~/.ssh/config`:

```
Host rust-dev
    HostName localhost
    Port 2222
    User rustdev
    StrictHostKeyChecking no
```

Then connect via: **Remote-SSH: Connect to Host** → `rust-dev`

---

### 2. Test Environment

**Target:** Synology NAS  
**Container Name:** `backend-container`  
**Purpose:** Testing with production-like setup

#### Features:
- ❌ No SSH access
- ✅ Mongo Express debugging tool
- ✅ Proxied via Synology reverse proxy
- ✅ TLS/HTTPS via Synology
- ✅ Medium logging (RUST_LOG=info)

#### Ports:
| Service | Internal Port | External Access |
|---------|---------------|-----------------|
| Application | 5665 | https://test_set.domain.synology.me |
| Mongo Express | 8080 | http://nas-ip:8080 |
| MongoDB | 27017 | Internal network only |

#### Deployment:

```bash
# From v0.4 directory
./deploy-v04.sh --test

# Or directly
cd test
./deploy-test.sh
```

#### Synology Reverse Proxy Setup:

1. **Control Panel** → **Application Portal** → **Reverse Proxy**
2. Click **Create**
3. Configure:
   - **Description:** SET Game Test
   - **Source:**
     - Protocol: HTTPS
     - Hostname: `test_set.domain.synology.me`
     - Port: 443
   - **Destination:**
     - Protocol: HTTP
     - Hostname: localhost
     - Port: 5665
4. Enable **HSTS** and **HTTP/2**

---

### 3. Production Environment

**Target:** Synology NAS  
**Container Name:** `server-container`  
**Purpose:** Production deployment

#### Features:
- ❌ No SSH access
- ❌ No Mongo Express
- ❌ MongoDB not exposed to host
- ✅ Proxied via Synology reverse proxy
- ✅ TLS/HTTPS via Synology
- ✅ Minimal logging (RUST_LOG=warn)
- ✅ Password validation checks

#### Ports:
| Service | Internal Port | External Access |
|---------|---------------|-----------------|
| Application | 5666 | https://set.domain.synology.me |
| MongoDB | 27017 | Internal network only (not exposed) |

#### Security Measures:
- 🔒 No debugging tools
- 🔒 No direct database access from host
- 🔒 Deployment requires password validation
- 🔒 Confirmation prompt before deployment
- 🔒 Emergency shell access only via `docker exec`

#### Deployment:

```bash
# IMPORTANT: Update passwords in prod/.env FIRST!
# Change DB_PASSWORD and DB_ADMIN_PASSWORD from default CHANGEME values

cd v0.4
./deploy-v04.sh --prod
```

The script will:
1. Check for default passwords (fails if found)
2. Prompt for confirmation
3. Deploy production services

#### Synology Reverse Proxy Setup:

1. **Control Panel** → **Application Portal** → **Reverse Proxy**
2. Click **Create**
3. Configure:
   - **Description:** SET Game Production
   - **Source:**
     - Protocol: HTTPS
     - Hostname: `set.domain.synology.me`
     - Port: 443
   - **Destination:**
     - Protocol: HTTP
     - Hostname: localhost
     - Port: 5666
4. Enable **HSTS** and **HTTP/2**
5. Configure **SSL Certificate** (Let's Encrypt recommended)

---

## ⚙️ Configuration

Each environment has its own `.env` file with appropriate defaults.

### Development (.env in dev/)

```bash
# Container configuration
CONTAINER_NAME=dev-container
HOSTNAME=dev-host

# Ports
SSH_PORT=2222              # VS Code Remote-SSH
APP_PORT=5665              # Application
MONGO_EXPRESS_PORT=8080    # Mongo Express

# Security (development-grade)
DB_PASSWORD=DevPassword123
RUST_LOG=debug
```

### Test (.env in test/)

```bash
# Container configuration
CONTAINER_NAME=backend-container
HOSTNAME=backend-host

# Ports (no SSH)
APP_PORT=5665              # Application
MONGO_EXPRESS_PORT=8080    # Mongo Express

# External URL
EXTERNAL_URL=https://test_set.domain.synology.me

# Security (test-grade)
DB_PASSWORD=TestPassword456!ChangeMe
RUST_LOG=info
```

### Production (.env in prod/)

```bash
# Container configuration
CONTAINER_NAME=server-container
HOSTNAME=server-host

# Ports (no SSH, no Mongo Express)
APP_PORT=5666              # Application only

# External URL
EXTERNAL_URL=https://set.domain.synology.me

# Security (MUST CHANGE BEFORE DEPLOYMENT!)
DB_PASSWORD=CHANGEME_SecureProductionPassword789!
DB_ADMIN_PASSWORD=CHANGEME_SecureProdAdmin789!
RUST_LOG=warn
```

---

## 💻 Usage

### Master Deployment Script

The master script orchestrates deployment to any environment:

```bash
# Deploy to development
./deploy-v04.sh --dev

# Deploy to test
./deploy-v04.sh --test

# Deploy to production (prompts for confirmation)
./deploy-v04.sh --prod
```

### Direct Deployment

You can also deploy directly from environment folders:

```bash
# Development
cd dev
./deploy-dev.sh

# Test
cd test
./deploy-test.sh

# Production
cd prod
./deploy-prod.sh
```

### Managing Services

Each environment uses its own compose file:

```bash
# Development
cd dev
docker compose -f docker-compose-dev.yml ps
docker compose -f docker-compose-dev.yml logs -f
docker compose -f docker-compose-dev.yml down

# Test
cd test
docker compose -f docker-compose-test.yml ps
docker compose -f docker-compose-test.yml logs -f
docker compose -f docker-compose-test.yml down

# Production
cd prod
docker compose -f docker-compose-prod.yml ps
docker compose -f docker-compose-prod.yml logs -f
docker compose -f docker-compose-prod.yml down
```

### Shell Access

**Development (SSH enabled):**
```bash
# Via VS Code Remote-SSH (recommended)
# Connect to 'rust-dev' host

# Or via docker
docker compose exec dev-container bash
```

**Test/Production (no SSH):**
```bash
# Test
cd test
docker compose -f docker-compose-test.yml exec backend-container bash

# Production
cd prod
docker compose -f docker-compose-prod.yml exec server-container bash
```

---

## 🔧 Customization

### Changing Ports

Edit the `.env` file in the target environment:

```bash
# dev/.env
SSH_PORT=2223              # Change SSH port
APP_PORT=5666              # Change application port
```

Then redeploy:
```bash
./deploy-v04.sh --dev
```

### Changing Database Configuration

Edit the `.env` file:

```bash
DB_NAME=my_custom_db
DB_USER=my_app_user
DB_PASSWORD=SecurePassword123

COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores
```

### Adding Custom Collections

Edit `.env` and add collection variables:

```bash
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores
COLLECTION_4=leaderboards
```

Then update the `mongo-init/01-init-db.js` (created by deployment script) to include your new collections.

---

## 🐛 Troubleshooting

### Port Conflicts

**Error:** `bind: address already in use`

**Solution:**
1. Check what's using the port: `netstat -ano | findstr :PORT` (Windows) or `lsof -i :PORT` (Linux)
2. Change port in `.env` file
3. Redeploy

### SSH Connection Fails (Dev)

**Checklist:**
- Container is running: `docker compose ps`
- SSH port is correct in VS Code config
- SSH key is in `~/.ssh/`
- Key is copied to `common/authorized_keys`

### Cannot Access External URL (Test/Prod)

**Checklist:**
- Synology reverse proxy is configured correctly
- DNS points to your Synology NAS
- Application is running on correct internal port
- Firewall allows HTTPS (443)

### Production Deployment Fails

**Common causes:**
1. **Default passwords not changed** - Update `prod/.env` passwords
2. **Confirmation not given** - Type `yes` when prompted
3. **Project files missing** - Ensure Rust project exists in `prod/rust_project/`

### MongoDB Connection Issues

**From container:**
```bash
docker compose exec CONTAINER_NAME bash
mongosh mongodb://mongo-db:27017 -u app_user -p PASSWORD
```

**Check logs:**
```bash
docker compose logs mongo-db
```

---

## 📊 Environment Comparison

| Feature | Development | Test | Production |
|---------|-------------|------|------------|
| **Target** | Local laptop | Synology NAS | Synology NAS |
| **Container Name** | dev-container | backend-container | server-container |
| **SSH Access** | ✅ Port 2222 | ❌ | ❌ |
| **Mongo Express** | ✅ Port 8080 | ✅ Port 8080 | ❌ |
| **MongoDB Port** | ✅ Exposed | ❌ Internal only | ❌ Internal only |
| **App Port** | 5665 | 5665 | 5666 |
| **External URL** | - | test_set.domain | set.domain |
| **Logging Level** | debug | info | warn |
| **Auto-restart** | No | Yes | Yes |
| **Password Check** | No | No | ✅ Yes |

---

## 🔐 Security Best Practices

### Development
- ✅ Use SSH keys (no passwords)
- ✅ Keep development isolated from production data
- ✅ Don't commit `.env` files to git

### Test
- ✅ Use test-specific passwords
- ✅ Limit Mongo Express access
- ✅ Keep test data separate from production

### Production
- ✅ **Change all default passwords before deployment**
- ✅ Use strong passwords (16+ characters, mixed case, numbers, symbols)
- ✅ Enable HSTS and HTTP/2 on reverse proxy
- ✅ Use Let's Encrypt for SSL certificates
- ✅ Regular backups of MongoDB data
- ✅ Monitor logs for suspicious activity
- ✅ Review and rotate passwords periodically

---

## 📚 Additional Resources

### Files in Each Environment

- **`.env`** - Environment configuration
- **`docker-compose-ENV.yml`** - Service definitions
- **`deploy-ENV.sh`** - Deployment automation
- **`rust_project/`** - Your Rust application code
- **`mongo-init/`** - MongoDB initialization scripts (auto-generated)

### Docker Commands Reference

```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f [service_name]

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v

# Rebuild images
docker compose build --no-cache

# Restart specific service
docker compose restart [service_name]
```

---

## 📝 Migration Guide

### From v0.3 to v0.4

1. **Copy your Rust project:**
   ```bash
   cp -r v0.3/rust_project v0.4/dev/rust_project
   cp -r v0.3/rust_project v0.4/test/rust_project
   cp -r v0.3/rust_project v0.4/prod/rust_project
   ```

2. **Review and update configuration:**
   - Update `dev/.env` with your development settings
   - Update `test/.env` with test environment settings
   - Update `prod/.env` with production settings (CHANGE PASSWORDS!)

3. **Deploy to new environment:**
   ```bash
   cd v0.4
   ./deploy-v04.sh --dev
   ```

4. **Test thoroughly before deploying to production**

---

## 🤝 Contributing

To customize for your project:

1. Clone/copy v0.4 directory
2. Update `.env` files in each environment
3. Modify `rust_project/` with your code
4. Test in dev environment first
5. Deploy to test for validation
6. Deploy to production when ready

---

## 📄 License

See LICENSE file in repository root.

---

## 🆘 Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review environment-specific configuration in `.env` files
3. Check container logs: `docker compose logs -f`
4. Verify Synology reverse proxy configuration (test/prod)

---

**Version 0.4** - Simplified multi-environment deployment for Rust applications with MongoDB  
**Last Updated:** November 2025
