# Rust Environment Builder (env_builder)

**Consistent development, test, and production environment deployment platform for Rust applications with MongoDB**

---

## 📋 Overview

The `env_builder` project provides automated deployment scripts to create consistent, containerized Rust environments across the full development lifecycle:

- **Development** - Local Windows laptop with full debugging tools and SSH access
- **Test** - Synology NAS with backend services for integration testing
- **Production** - Synology NAS with optimized, secure server deployment

All environments are **consistent** - using the same base configuration with environment-specific optimizations. Each environment is fully containerized using Docker and includes:
- Rust toolchain and build environment (dev only; test and prod use pre-built binaries)
- MongoDB database with initialization
- Environment-specific configuration and security
- Automated setup and deployment scripts

---

## 🚀 Quick Start

### Prerequisites

- Docker Desktop installed and running
- PowerShell (Windows) or Bash (Linux/macOS/WSL)
- Git (for cloning your Rust projects)

### Deploy Development Environment

From the root directory:

```powershell
cd C:\rustdev\env_builder
.\deploy.ps1 --dev
```

Or using bash:

```bash
cd /c/rustdev/env_builder
./deploy.sh --dev
```

### Connect with VS Code

1. Press `Ctrl+Shift+P`
2. Type: **Remote-SSH: Connect to Host**
3. Select: **rust-dev**
4. Open folder: `/workspace`
5. Clone your repository:
   ```bash
   git clone https://github.com/your-username/your-project.git
   cd your-project
   cargo build
   ```

---

## 📦 Deployment Options

### Development Environment
```powershell
.\deploy.ps1 --dev
```
- **Target:** Local laptop
- **Features:** SSH access, Rust toolchain, full debugging, Mongo Express
- **Ports:** SSH (2222), App (5665), MongoDB (27017), Mongo Express (8080)

### Test Environment
```powershell
.\deploy.ps1 --test
```
- **Target:** Synology NAS
- **Features:** Backend services (pre-built binary), Mongo Express for debugging
- **Access:** Via Synology reverse proxy (HTTPS)

### Production Environment
```powershell
.\deploy.ps1 --prod
```
- **Target:** Synology NAS
- **Features:** Optimized server (pre-built binary), no debugging tools, enhanced security
- **Access:** Via Synology reverse proxy (HTTPS)

---

## 📖 Documentation

### Current Version: v0.4

For detailed documentation, see:
- **[v0.4 README](v0.4/README-v04.md)** - Comprehensive guide for version 0.4
- **[Development Workflow](v0.4/dev/WORKFLOW.md)** - Step-by-step development workflow
- **[Quick Start Guide](v0.4/QUICKSTART.md)** - Fast setup instructions

### Version-Specific Documentation

Each version has its own documentation in its directory:
- `v0.1/` - Initial prototype
- `v0.2/` - Enhanced with environment variables
- `v0.3/` - Multi-environment support
- `v0.4/` - **Current** - Simplified architecture with separate configs

---

## 🛠️ Project Structure

```
env_builder/
├── deploy.ps1                 # Master deployment script (PowerShell)
├── deploy.sh                  # Master deployment script (Bash)
├── README.md                  # This file
├── v0.4/                      # Current version
│   ├── deploy-v04.ps1         # Version-specific deployment
│   ├── deploy-v04.sh
│   ├── README-v04.md          # Detailed v0.4 documentation
│   ├── QUICKSTART.md
│   ├── common/                # Shared Dockerfile
│   ├── dev/                   # Development environment
│   │   ├── .env               # Dev configuration
│   │   ├── docker-compose-dev.yml
│   │   ├── deploy-dev.ps1
│   │   ├── deploy-dev.sh
│   │   ├── cleanup.ps1        # Complete cleanup script
│   │   └── WORKFLOW.md        # Development workflow guide
│   ├── test/                  # Test environment
│   └── prod/                  # Production environment
└── v0.1/ v0.2/ v0.3/          # Previous versions
```

---

## 🔧 Common Tasks

### Clean Up Development Environment

Complete cleanup (removes all containers, images, and data):
```powershell
cd v0.4\dev
.\cleanup.ps1
```

### Restart Services

```powershell
cd v0.4\dev
docker compose -f docker-compose-dev.yml restart
```

### View Logs

```powershell
cd v0.4\dev
docker compose -f docker-compose-dev.yml logs -f
```

### Stop Services

```powershell
cd v0.4\dev
docker compose -f docker-compose-dev.yml down
```

---

## 🎯 Key Features

### Version 0.4 Highlights

✨ **Consistent Multi-Environment Architecture** - Same base configuration across dev/test/prod with environment-specific optimizations  
✨ **Simplified Deployment** - Dedicated folders and configs for each environment  
✨ **No Conditional Logic** - Each environment has its own complete configuration  
✨ **Clear Security Boundaries** - SSH and debugging tools only where appropriate  
✨ **Production Safety** - Password validation and confirmation prompts  
✨ **WSL Compatibility** - Fixed mount issues for Windows + Docker Desktop  
✨ **Interactive Cleanup** - Automated detection and handling of existing directories  

---

## 🔐 Security Notes

### Development
- SSH access enabled (key-based authentication)
- Debugging tools included (Mongo Express)
- Full Rust toolchain for compilation
- Development-grade passwords acceptable

### Test
- No SSH access (use `docker exec` if needed)
- Debugging tools available (Mongo Express)
- No Rust toolchain (runs pre-built binary)
- Test-specific credentials required

### Production
- No SSH access
- No debugging tools (Mongo Express disabled)
- No Rust toolchain (runs pre-built binary)
- Strong passwords required (validated during deployment)
- Confirmation prompt before deployment
- MongoDB not exposed to host

---

## 🐛 Troubleshooting

### "Existing project directory found" message
- Default option (2) will delete and start fresh
- Choose option 1 to keep existing files
- This prevents issues with stale files from previous deployments

### Docker Desktop not running
```
Error: Cannot connect to the Docker daemon
```
Solution: Start Docker Desktop and wait for it to be ready

### Port conflicts
```
Error: bind: address already in use
```
Solution: Edit the `.env` file in the environment directory and change the conflicting port

### Need more help?
See the detailed documentation:
- [v0.4 README](v0.4/README-v04.md) - Full documentation
- [Troubleshooting section](v0.4/README-v04.md#troubleshooting) - Common issues

---

## 📝 Version History

- **v0.4** (November 2025) - Current - Simplified multi-environment architecture
- **v0.3** - Multi-environment support with conditional logic
- **v0.2** - Environment variables and configuration files
- **v0.1** - Initial prototype

For detailed version history and migration guides, see [VERSIONING-SUMMARY.md](VERSIONING-SUMMARY.md)

---

## 🤝 Contributing

To create a new version:

1. Copy the latest version directory (e.g., `cp -r v0.4 v0.5`)
2. Update configuration and scripts as needed
3. Update the master deployment scripts (`deploy.ps1` and `deploy.sh`):
   - Change `$LatestVersion = "v0.5"`
   - Update the version script path
4. Document changes in the new version's README
5. Update this root README to reference the new version

---

## 📄 License

See [LICENSE](LICENSE) file in repository root.

---

## 📞 Support

For questions or issues:
1. Check the [v0.4 documentation](v0.4/README-v04.md)
2. Review the [troubleshooting guide](v0.4/README-v04.md#troubleshooting)
3. Examine container logs: `docker compose logs -f`

---

**Current Version:** v0.4  
**Last Updated:** November 2025  
**Maintainer:** Thierry Souche
