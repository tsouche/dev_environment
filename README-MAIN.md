# Rust Development Environment for Windows 11

A containerized Rust development environment optimized for Windows 11, combining VS Code on Windows with Linux development environment via Docker Desktop.

## 🎯 Overview

This repository provides version-controlled development environments featuring:

- **VS Code on Windows 11** - Remote SSH integration
- **Ubuntu Container** - Isolated Linux development environment
- **Rust Toolchain** - Complete Rust development stack
- **MongoDB Database** - Integrated database support
- **Automated Deployment** - Scripts for easy setup

## 📦 Available Versions

### Current Version: v0.2 (Recommended)

The latest stable version with MongoDB integration and enhanced deployment automation.

**Location:** `v0.2/`

**Quick Start:**
```powershell
# Windows PowerShell
cd v0.2
.\deploy-v02.ps1

# Linux/WSL/Git Bash
cd v0.2
chmod +x deploy-v02.sh
./deploy-v02.sh
```

**Documentation:** See [v0.2/documentation-v02.md](v0.2/documentation-v02.md)

**Key Features:**
- Ubuntu 22.04 LTS base
- Rust stable toolchain
- MongoDB 7.0 with Mongo Express
- SSH key-based authentication
- Automated deployment scripts
- NAS-compatible user/group IDs

---

### Legacy Version: v0.1

Basic Rust development environment without database integration.

**Location:** `v0.1/`

**Documentation:** See [v0.1/README.md](v0.1/README.md)

**Note:** Consider migrating to v0.2 for enhanced features.

---

## 📋 Repository Structure

```
dev_environment/
├── README.md                    # This file
├── v0.1/                        # Legacy version
│   ├── dockerfile v0.1
│   └── readme.md
├── v0.2/                        # Current version (recommended)
│   ├── dockerfile.v0.2
│   ├── docker-compose-v02.yml
│   ├── deploy-v02.sh
│   ├── deploy-v02.ps1
│   ├── documentation-v02.md
│   └── VERSION.md
├── dockerfile.v0.2              # Reference files (root level)
├── docker-compose.yml
├── deploy.sh
├── deploy.ps1
└── documentation.md
```

## 🚀 Getting Started

### Prerequisites

1. **Windows 11** (Pro/Enterprise/Home)
2. **Docker Desktop** 4.x+ with WSL 2 backend
3. **VS Code** with Remote-SSH extension
4. **SSH key pair** (ed25519 or RSA)

### Installation

1. **Clone this repository:**
   ```bash
   git clone <repository-url>
   cd dev_environment
   ```

2. **Navigate to desired version:**
   ```bash
   cd v0.2  # Recommended
   ```

3. **Run deployment script:**
   ```powershell
   # Windows
   .\deploy-v02.ps1
   
   # Linux/WSL
   ./deploy-v02.sh
   ```

4. **Connect VS Code:**
   - Configure SSH connection (instructions in deployment output)
   - Connect via Remote-SSH
   - Open `/workspace/set_backend`

## 📚 Documentation

- **v0.2 Documentation:** [v0.2/documentation-v02.md](v0.2/documentation-v02.md)
  - Complete setup guide
  - Troubleshooting section
  - Advanced configuration
  - Daily workflow examples

- **v0.2 Version Info:** [v0.2/VERSION.md](v0.2/VERSION.md)
  - Release notes
  - Feature list
  - Migration guide

## 🔄 Version Comparison

| Feature | v0.1 | v0.2 |
|---------|------|------|
| Ubuntu Base | 22.04 | 22.04 |
| Rust Toolchain | ✅ | ✅ |
| SSH Access | ✅ | ✅ |
| MongoDB | ❌ | ✅ |
| Mongo Express | ❌ | ✅ |
| Automated Deployment | ❌ | ✅ |
| Docker Compose | ❌ | ✅ |
| Volume Caching | ❌ | ✅ |
| Documentation | Basic | Comprehensive |

## 🛠️ Common Tasks

### Start Environment
```powershell
cd v0.2
docker compose -f docker-compose-v02.yml up -d
```

### Stop Environment
```powershell
docker compose -f docker-compose-v02.yml down
```

### View Logs
```powershell
docker compose -f docker-compose-v02.yml logs -f
```

### Access Container Shell
```powershell
docker compose -f docker-compose-v02.yml exec rust-dev bash
```

## 🔧 Troubleshooting

For detailed troubleshooting, see version-specific documentation:
- [v0.2 Troubleshooting](v0.2/documentation-v02.md#troubleshooting)

### Quick Fixes

**Cannot connect via SSH:**
```powershell
docker compose ps  # Check if running
docker compose logs rust-dev  # Check logs
```

**Port already in use:**
```powershell
netstat -ano | findstr :2222  # Find conflicting process
```

**Permission errors:**
```powershell
docker compose exec rust-dev sudo chown -R rustdev:rustdevteam /workspace
```

## 📖 Additional Resources

- [Rust Documentation](https://doc.rust-lang.org/book/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [VS Code Remote-SSH](https://code.visualstudio.com/docs/remote/ssh)
- [MongoDB Rust Driver](https://www.mongodb.com/docs/drivers/rust/)

## 🤝 Contributing

To create a new version:

1. Create new version directory (e.g., `v0.3/`)
2. Copy and update files with new version naming
3. Update references in all files
4. Add version to this README
5. Create VERSION.md for the new version

## 📝 License

See [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues:
1. Check version-specific documentation
2. Review troubleshooting guides
3. Check Docker Desktop status
4. Verify prerequisites are met

---

**Current Version:** 0.2  
**Repository:** dev_environment  
**Last Updated:** November 8, 2025  
**Tested On:** Windows 11 Pro (22H2), Docker Desktop 4.25.0, VS Code 1.84.0

---

## Quick Links

- [📦 Version 0.2 (Current)](v0.2/)
- [📖 v0.2 Documentation](v0.2/documentation-v02.md)
- [🚀 v0.2 Quick Start](v0.2/VERSION.md#quick-start)
- [📋 v0.1 (Legacy)](v0.1/)
