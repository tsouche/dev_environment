# Rust DevContainer Image Builder

## Quick Start

```bash
./build_and_push_on_nas.sh [VERSION]
```

Example:
```bash
./build_and_push_on_nas.sh 0.5.0
```

Default version: `0.5.0` (if not specified)

## Prerequisites

1. **SSH Access to NAS**: Ensure you can SSH to `thierry@100.100.10.1:5522`
2. **DockerHub Credentials**: The script will automatically check and prompt for login if needed
3. **Required Files**: The following files must exist in this directory:
   - `Dockerfile.rustdev` (main Dockerfile)
   - `authorized_keys` (SSH keys for rustdev user)
   - `install_vscode_extensions.sh` (VS Code extension installer)
   - `devcontainer.json` (Dev container configuration)

## What It Does

1. Validates all required files exist locally
2. Creates temporary directory on NAS (`/tmp/docker_build_rustdev_*`)
3. Transfers Dockerfile and support files via SCP
4. **Checks DockerHub login status (prompts for password if needed)**
5. Builds image on NAS: `tsouche/rust_devcontainer:vX.Y.Z`
6. Tags with: `vX.Y.Z`, `vX.Y`, `latest`
7. Pushes all tags to DockerHub
8. Cleans up temporary files on NAS

## Image Details

- **Base**: Ubuntu 22.04
- **User**: rustdev (UID 1026, GID 110)
- **Rust**: Installed via rustup (stable toolchain)
- **Features**:
  - SSH server configured and running
  - VS Code extensions auto-install on first login
  - MongoDB tools (mongosh)
  - Common dev tools (curl, wget, git, build-essential, etc.)

## Troubleshooting

**Missing files error**: Ensure all 3 support files exist in this directory.
**SSH connection fails**: Check NAS is accessible at `100.100.10.1:5522`
**Build fails on NAS**: SSH to NAS and check Docker is running
**DockerHub login fails**: Verify your DockerHub credentials are correct

---
**Last Updated**: 2025-01-19
