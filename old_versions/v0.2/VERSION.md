# Version 0.2

**Release Date:** November 2025

## File Structure

This directory contains Version 0.2 of the Rust Development Environment for Windows 11.

### Files in this Version

| File | Description |
|------|-------------|
| `dockerfile.v0.2` | Ubuntu 22.04 + Rust + SSH + MongoDB client configuration |
| `docker-compose-v02.yml` | Multi-container orchestration (rust-dev, MongoDB, Mongo Express) |
| `deploy-v02.sh` | Bash deployment script for Linux/WSL/Git Bash |
| `deploy-v02.ps1` | PowerShell deployment script for Windows |
| `documentation-v02.md` | Complete setup and usage documentation |
| `VERSION.md` | This file - version information |

## Key Features

### Development Environment
- **Base OS:** Ubuntu 22.04 LTS
- **Rust Toolchain:** Stable (via rustup)
- **SSH Access:** Key-based authentication, Port 2222
- **User:** rustdev (UID: 1026, GID: 110)

### Database Integration
- **MongoDB:** Version 7.0 (Jammy)
- **Mongo Express:** Web UI on port 8081
- **Database:** set_game_db with initialized collections

### Deployment
- Automated deployment scripts for Windows and Linux
- Pre-flight checks for Docker Desktop
- Automatic directory structure creation
- SSH key management
- MongoDB initialization scripts

## Quick Start

### Windows (PowerShell)
```powershell
cd path\to\dev_environment\v0.2
.\deploy-v02.ps1
```

### Linux/WSL/Git Bash
```bash
cd /path/to/dev_environment/v0.2
chmod +x deploy-v02.sh
./deploy-v02.sh
```

## Documentation

See `documentation-v02.md` for complete setup instructions, troubleshooting guide, and advanced configuration options.

## Compatibility

- **Tested On:** Windows 11 Pro (22H2)
- **Docker Desktop:** Version 4.25.0+
- **VS Code:** Version 1.84.0+
- **WSL:** Version 2

## Known Issues

None reported for this version.

## Migration Notes

### From v0.1 to v0.2
- All configuration files now follow v02 naming convention
- Files organized in dedicated v0.2 directory
- Updated docker-compose to reference dockerfile.v0.2 explicitly
- Enhanced deployment scripts with version identifiers

## Support

For issues or questions, refer to:
1. `documentation-v02.md` - Troubleshooting section
2. Docker logs: `docker compose logs`
3. Pre-flight checks in deployment scripts

---

**Version:** 0.2  
**Last Updated:** November 8, 2025
