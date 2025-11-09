# Version 0.4 - Multi-Environment Deployment

**Release Date:** November 2025  
**Major Version:** 0.4  
**Previous Version:** 0.3

---

## Overview

Version 0.4 represents a major architectural shift from complex conditional deployment to **environment-specific configuration sets**. This approach significantly simplifies deployment and maintenance by providing dedicated, self-contained configurations for each target environment.

---

## Key Changes

### Architecture

**Before (v0.3):**
- Single docker-compose file with complex conditionals
- Single .env file for all environments
- Deployment scripts with environment-detection logic
- Profiles and conditional service deployment

**After (v0.4):**
- Separate folders for dev/, test/, prod/
- Environment-specific docker-compose files
- Dedicated .env per environment
- Simple master deployment script with `--dev`, `--test`, `--prod` flags

### File Structure

```
v0.4/
├── deploy-v04.sh              # Master orchestration script
├── deploy-v04.ps1             # Master orchestration script (PowerShell)
├── common/
│   └── dockerfile.v0.4        # Shared Dockerfile
├── dev/                       # Development environment
│   ├── .env
│   ├── docker-compose-dev.yml
│   ├── deploy-dev.sh
│   └── deploy-dev.ps1
├── test/                      # Test environment
│   ├── .env
│   ├── docker-compose-test.yml
│   └── deploy-test.sh
└── prod/                      # Production environment
    ├── .env
    ├── docker-compose-prod.yml
    └── deploy-prod.sh
```

---

## Environment Specifications

### Development Environment

**Purpose:** Local development with full debugging capabilities

**Configuration:**
- Container: `dev-container`
- SSH: Enabled (port 2222)
- Mongo Express: Enabled (port 8080)
- Application Port: 5665
- MongoDB: Exposed to host (27017)
- Logging: DEBUG level

**Use Case:**
- Code development with VS Code Remote-SSH
- Real-time debugging
- Database inspection via Mongo Express
- Hot-reload development workflow

### Test Environment

**Purpose:** Integration testing on Synology NAS

**Configuration:**
- Container: `backend-container`
- SSH: Disabled
- Mongo Express: Enabled (port 8080)
- Application Port: 5665
- MongoDB: Internal network only
- External URL: https://test_set.domain.synology.me
- Logging: INFO level

**Use Case:**
- Backend testing in production-like environment
- QA and staging
- Integration testing
- Performance testing

### Production Environment

**Purpose:** Live production deployment on Synology NAS

**Configuration:**
- Container: `server-container`
- SSH: Disabled
- Mongo Express: Disabled
- Application Port: 5666
- MongoDB: Internal network only (not exposed to host)
- External URL: https://set.domain.synology.me
- Logging: WARN level
- Password Validation: Enabled

**Use Case:**
- Live production server
- Public-facing application
- Maximum security posture

---

## New Features

### 1. Master Deployment Script

Single entry point for all deployments:

```bash
./deploy-v04.sh --dev      # Development
./deploy-v04.sh --test     # Test
./deploy-v04.sh --prod     # Production
```

**Features:**
- Environment validation
- File existence checks
- Confirmation prompts (test/prod)
- Automatic environment-specific script execution

### 2. Environment Isolation

Each environment is completely self-contained:
- Own configuration files
- Own Docker Compose definition
- Own deployment scripts
- Own runtime data (volumes with environment prefix)

**Benefits:**
- No configuration conflicts
- Easy to understand and maintain
- Can run multiple environments simultaneously
- Clear separation of concerns

### 3. Production Safety

Enhanced security measures for production:
- Default password detection (fails deployment)
- Mandatory password change requirement
- Confirmation prompt before deployment
- No debugging tools exposed
- MongoDB not exposed to host network

### 4. Simplified Docker Compose Files

No more complex conditionals:
- `docker-compose-dev.yml` - Always includes SSH, Mongo Express
- `docker-compose-test.yml` - No SSH, includes Mongo Express
- `docker-compose-prod.yml` - No SSH, no Mongo Express, no exposed MongoDB port

### 5. Container Naming Convention

Clear naming based on environment:
- Development: `dev-container`, `dev-mongodb`, `dev-mongo-express`
- Test: `backend-container`, `test-mongodb`, `test-mongo-express`
- Production: `server-container`, `prod-mongodb`

### 6. Volume Prefixing

Environment-specific volume names prevent conflicts:
- `dev-mongodb-data`, `dev-cargo-cache`, `dev-target-cache`
- `test-mongodb-data`, `test-cargo-cache`, `test-target-cache`
- `prod-mongodb-data`, `prod-cargo-cache`, `prod-target-cache`

---

## Breaking Changes from v0.3

### File Organization
- ❌ No more single docker-compose file
- ❌ No more conditional profiles
- ✅ Must use environment-specific folders

### Deployment Commands
- ❌ Old: `./deploy-v03.sh` (auto-detected environment)
- ✅ New: `./deploy-v04.sh --dev|--test|--prod` (explicit)

### Configuration
- ❌ Single .env file for all environments
- ✅ Separate .env file per environment

### Port Assignments
- Development: 5665 (same)
- Test: 5665 (same)
- Production: 5666 (changed from 5665 for clear separation)

---

## Migration Path

### From v0.3 to v0.4

1. **Copy project files to each environment:**
   ```bash
   cp -r v0.3/rust_project v0.4/dev/
   cp -r v0.3/rust_project v0.4/test/
   cp -r v0.3/rust_project v0.4/prod/
   ```

2. **Transfer configuration:**
   - Review v0.3 `.env` settings
   - Apply to appropriate v0.4 `.env` files
   - Adjust ports if needed

3. **Update passwords (production):**
   - Edit `v0.4/prod/.env`
   - Change `DB_PASSWORD`
   - Change `DB_ADMIN_PASSWORD`

4. **Deploy:**
   ```bash
   cd v0.4
   ./deploy-v04.sh --dev
   ```

5. **Test thoroughly in dev, then test, then prod**

---

## Deployment Workflow

### Recommended Flow

```
1. Development
   ↓
   - Code and test locally
   - Use VS Code Remote-SSH
   - Debug with Mongo Express
   ↓
2. Test
   ↓
   - Deploy to Synology NAS (test environment)
   - Integration testing
   - Performance validation
   - External access testing
   ↓
3. Production
   ↓
   - Update passwords
   - Review configuration
   - Deploy with confirmation
   - Monitor logs
```

### Command Sequence

```bash
# Development
cd v0.4
./deploy-v04.sh --dev
# ... develop and test ...
docker compose -f dev/docker-compose-dev.yml down

# Test
./deploy-v04.sh --test
# ... integration testing ...
docker compose -f test/docker-compose-test.yml logs -f

# Production (after testing)
# 1. Update prod/.env passwords
# 2. Deploy
./deploy-v04.sh --prod
# Type 'yes' to confirm
```

---

## Technical Details

### Shared Components

**dockerfile.v0.4 (common/):**
- Ubuntu 22.04 base
- Rust toolchain (stable)
- SSH server configuration
- MongoDB client tools
- Common to all environments

### Environment-Specific Components

**docker-compose files:**
- Port mappings specific to environment
- Service inclusion (SSH, Mongo Express)
- Network names (prefixed with environment)
- Volume names (prefixed with environment)

**Deployment scripts:**
- Directory creation logic
- SSH key handling (dev only)
- MongoDB initialization
- Sample project creation
- Environment-specific messaging

### Network Isolation

Each environment uses its own Docker network:
- `dev-network`
- `test-network`
- `prod-network`

This ensures complete isolation between environments.

---

## Security Improvements

### Development
- SSH key-based authentication only
- No passwords for SSH
- MongoDB exposed only to localhost

### Test
- No SSH access
- Shell access via `docker exec` only
- Mongo Express for debugging
- MongoDB internal network only

### Production
- No SSH access
- No debugging tools
- MongoDB internal network only (not exposed to host)
- Password validation before deployment
- Confirmation required for deployment
- Minimal logging (WARN level)

---

## Performance Considerations

### Resource Usage

**Development:**
- 3 containers (dev, mongodb, mongo-express)
- Higher memory usage (debugging tools)
- Suitable for local machines

**Test:**
- 3 containers (backend, mongodb, mongo-express)
- Medium memory usage
- Suitable for Synology NAS

**Production:**
- 2 containers (server, mongodb)
- Lower memory usage (no debugging tools)
- Optimized for Synology NAS

### Volume Management

Separate volumes per environment prevent:
- Build cache conflicts
- Data corruption between environments
- Cargo registry duplication issues

---

## Testing Strategy

### Development Testing
1. Deploy dev environment
2. Connect via VS Code Remote-SSH
3. Run `cargo build` and `cargo test`
4. Test MongoDB connection
5. Inspect database via Mongo Express

### Integration Testing
1. Deploy test environment
2. Test external URL access
3. Verify reverse proxy configuration
4. Load testing
5. Integration test suite

### Production Validation
1. Deploy to production
2. Verify external URL
3. Monitor logs
4. Performance monitoring
5. Security audit

---

## Future Enhancements

Potential improvements for v0.5:
- Docker Compose v2 native features
- Health checks for all services
- Automated backup scripts per environment
- Monitoring and alerting integration
- CI/CD pipeline templates
- Environment variable validation
- SSL certificate automation

---

## Known Limitations

1. **Windows SSH key format** - May need conversion for authorized_keys
2. **Manual Synology setup** - Reverse proxy must be configured manually
3. **No auto-migration** - Requires manual copying from v0.3
4. **PowerShell scripts** - Only deploy-dev.ps1 implemented, test/prod pending

---

## Troubleshooting

### Common Issues

**"Environment directory not found"**
- Ensure you're in v0.4 directory
- Check folder structure exists

**"Default password detected"**
- Edit prod/.env
- Change CHANGEME passwords

**"Port already in use"**
- Stop conflicting services
- Or change port in .env

**"Cannot connect to MongoDB"**
- Check container is running
- Verify network connectivity
- Review docker-compose logs

---

## Changelog

### v0.4.0 (November 2025)

**Added:**
- Separate environments (dev, test, prod)
- Master deployment script with --env flags
- Environment-specific docker-compose files
- Production password validation
- Confirmation prompts for test/prod
- Comprehensive README-v04.md

**Changed:**
- Architecture from monolithic to modular
- File structure from flat to nested
- Deployment from auto-detect to explicit
- Production port from 5665 to 5666

**Removed:**
- Conditional docker-compose profiles
- Environment detection logic
- Single .env approach

**Fixed:**
- Configuration conflicts between environments
- SSH port conflicts
- Volume naming collisions
- Production security gaps

---

## Credits

**Version 0.4** developed as an evolution of v0.3 based on feedback for:
- Simpler deployment process
- Clearer environment separation
- Enhanced production security
- Easier troubleshooting

---

**For detailed usage instructions, see README-v04.md**
