# Quick Start Guide - v0.4

## What You Have

Version 0.4 with **three separate deployment environments**:

```
v0.4/
├── deploy-v04.sh           ← Master script
├── deploy-v04.ps1          ← Master script (PowerShell)
├── README-v04.md           ← Full documentation
├── VERSION.md              ← Release notes
├── common/
│   └── dockerfile.v0.4     ← Shared Docker image
├── dev/                    ← Development environment
├── test/                   ← Test environment (Synology NAS)
└── prod/                   ← Production environment (Synology NAS)
```

---

## Three Deployment Modes

### 1. **DEV** - Development Laptop
- Container: `dev-container`
- SSH: ✅ Port 2222 (VS Code Remote)
- Application: http://localhost:5665
- Mongo Express: ✅ http://localhost:8080
- Purpose: Code development

### 2. **TEST** - Synology NAS
- Container: `backend-container`
- SSH: ❌ (use docker exec)
- Application: https://test_set.domain.synology.me
- Mongo Express: ✅ http://localhost:8080
- Purpose: Integration testing

### 3. **PROD** - Synology NAS
- Container: `server-container`
- SSH: ❌ (emergency docker exec only)
- Application: https://set.domain.synology.me
- Mongo Express: ❌ (security)
- Purpose: Live production

---

## Getting Started

### Step 1: Deploy Development Environment

```bash
cd v0.4
./deploy-v04.sh --dev
```

This will:
- Create project structure
- Copy your SSH key
- Build Docker images
- Start dev-container, MongoDB, and Mongo Express
- Display connection info

### Step 2: Connect with VS Code

Add to `~/.ssh/config`:
```
Host rust-dev
    HostName localhost
    Port 2222
    User rustdev
    StrictHostKeyChecking no
```

In VS Code:
1. Press `Ctrl+Shift+P`
2. Type "Remote-SSH: Connect to Host"
3. Select "rust-dev"
4. Open folder: `/workspace/rust_project`

### Step 3: Start Coding

Inside the container:
```bash
cd /workspace/rust_project
cargo build
cargo run
```

---

## Deploying to Test

### Before Deploying

1. Copy your project to test environment:
   ```bash
   cp -r dev/rust_project test/
   ```

2. Review test configuration:
   ```bash
   cat test/.env
   ```

### Deploy

```bash
./deploy-v04.sh --test
```

### Configure Synology Reverse Proxy

1. Go to: **Control Panel** → **Application Portal** → **Reverse Proxy**
2. Click **Create**
3. Configure:
   - Source: HTTPS, `test_set.domain.synology.me`, 443
   - Destination: HTTP, localhost, 5665
4. Enable HSTS and HTTP/2

Access at: https://test_set.domain.synology.me

---

## Deploying to Production

### Before Deploying

⚠️ **CRITICAL: Change Passwords!**

Edit `prod/.env`:
```bash
DB_PASSWORD=YourSecurePassword123!
DB_ADMIN_PASSWORD=YourSecureAdminPassword456!
```

Remove "CHANGEME_" prefix and use strong passwords (16+ characters).

### Deploy

```bash
./deploy-v04.sh --prod
```

The script will:
1. Check for default passwords (fail if found)
2. Ask for confirmation
3. Deploy if confirmed

### Configure Synology Reverse Proxy

1. Go to: **Control Panel** → **Application Portal** → **Reverse Proxy**
2. Click **Create**
3. Configure:
   - Source: HTTPS, `set.domain.synology.me`, 443
   - Destination: HTTP, localhost, 5666
4. Enable HSTS and HTTP/2
5. Configure SSL certificate (Let's Encrypt)

Access at: https://set.domain.synology.me

---

## Useful Commands

### View Status

```bash
# Development
cd dev
docker compose -f docker-compose-dev.yml ps

# Test
cd test
docker compose -f docker-compose-test.yml ps

# Production
cd prod
docker compose -f docker-compose-prod.yml ps
```

### View Logs

```bash
# All services
docker compose -f docker-compose-dev.yml logs -f

# Specific service
docker compose -f docker-compose-dev.yml logs -f dev-container
```

### Stop Services

```bash
docker compose -f docker-compose-dev.yml down
```

### Shell Access

**Development (via SSH - preferred):**
- Use VS Code Remote-SSH

**Development (via Docker):**
```bash
cd dev
docker compose -f docker-compose-dev.yml exec dev-container bash
```

**Test/Production:**
```bash
cd test
docker compose -f docker-compose-test.yml exec backend-container bash

cd prod
docker compose -f docker-compose-prod.yml exec server-container bash
```

---

## Service URLs

### Development
- SSH: localhost:2222
- Application: http://localhost:5665
- MongoDB: localhost:27017
- Mongo Express: http://localhost:8080

### Test
- Application (internal): http://localhost:5665
- Application (external): https://test_set.domain.synology.me
- Mongo Express: http://localhost:8080

### Production
- Application (internal): http://localhost:5666
- Application (external): https://set.domain.synology.me
- MongoDB: Internal network only
- Mongo Express: Disabled

---

## Configuration Files

Each environment has its own `.env` file:

**dev/.env**
- Development settings
- SSH enabled
- Debug logging
- All tools enabled

**test/.env**
- Test settings
- No SSH
- Info logging
- Debugging tools enabled

**prod/.env**
- Production settings
- No SSH, no debugging tools
- Warn logging
- **Change passwords before deployment!**

---

## Troubleshooting

### Port Already in Use

Change port in environment's `.env` file:
```bash
APP_PORT=5667  # or any available port
```

Then redeploy.

### SSH Connection Fails (Dev)

1. Check container is running: `docker compose ps`
2. Verify SSH key exists: `ls ~/.ssh/id_*.pub`
3. Check authorized_keys: `cat common/authorized_keys`
4. Rebuild if needed: `docker compose build --no-cache`

### Cannot Access External URL

1. Check Synology reverse proxy configuration
2. Verify DNS points to your NAS
3. Check application is running on correct port
4. Review firewall settings

### Database Connection Issues

```bash
# Check MongoDB is running
docker compose ps

# Test connection from container
docker compose exec CONTAINER_NAME bash
mongosh mongodb://mongo-db:27017 -u app_user -p YOUR_PASSWORD

# Check MongoDB logs
docker compose logs mongo-db
```

---

## Next Steps

1. ✅ Deploy development environment
2. ✅ Connect via VS Code Remote-SSH
3. ✅ Build and test your Rust project
4. ✅ Deploy to test environment
5. ✅ Configure Synology reverse proxy (test)
6. ✅ Integration testing
7. ✅ Update production passwords
8. ✅ Deploy to production
9. ✅ Configure Synology reverse proxy (prod)
10. ✅ Monitor and maintain

---

## Documentation

- **README-v04.md** - Full documentation
- **VERSION.md** - Release notes and changes
- **This file** - Quick reference

---

## Support

For detailed information on any topic, see:
- README-v04.md - Complete guide
- Environment-specific .env files - Configuration options
- Docker Compose files - Service definitions
- Deployment scripts - Automation details

---

**Version 0.4** - Simple, clear, secure multi-environment deployment  
**Last Updated:** November 2025
