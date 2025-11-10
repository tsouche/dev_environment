# SET Backend Test/Prod Base Image

Docker base image for SET Backend test and production runtime environments.

## Overview

**Image**: `tsouche/set_backend_testprod`  
**Purpose**: Common runtime environment for SET Backend test and production deployments  
**Size**: ~300MB (Ubuntu + minimal runtime dependencies)

## What's Inside the Image

- **Base**: Ubuntu 22.04 LTS
- **Runtime Libraries**: libssl3, ca-certificates, curl
- **User Setup**: Pre-configured user `thierry` (UID 1026, GID 100)
- **Directories**: `/app` (workdir), `/data` (data storage)

**Note**: MongoDB Shell (mongosh) is NOT included in the base image. It's added only in the test environment where needed for debugging.

## Quick Start

```bash
./build_and_push_on_nas.sh [VERSION]
```

Example:
```bash
# Auto-detect version from Cargo.toml
./build_and_push_on_nas.sh

# Or specify version explicitly
./build_and_push_on_nas.sh 0.6.0
```

## Prerequisites

1. **SSH Access to NAS**: Ensure you can SSH to `thierry@100.100.10.1:5522`
2. **DockerHub Credentials**: The script will automatically check and prompt for login if needed
3. **Cargo.toml**: Version will be auto-detected from `../../Cargo.toml`

## What It Does

1. Detects version from Cargo.toml (or uses provided version)
2. Creates temporary directory on NAS
3. Transfers Dockerfile via SCP
4. **Checks DockerHub login status (prompts for password if needed)**
5. Builds image on NAS: `tsouche/set_backend_testprod:vX.Y.Z`
6. Tags with: `vX.Y.Z`, `vX.Y`, `latest`
7. Pushes all tags to DockerHub
8. Cleans up temporary files on NAS

## Version Management

The image version is **tied to the SET Backend version** from `Cargo.toml`:

- SET Backend v0.6.0 → Image `tsouche/set_backend_testprod:v0.6.0`
- SET Backend v0.7.0 → Image `tsouche/set_backend_testprod:v0.7.0`

**Important**: Rebuild and push the image whenever SET Backend version changes!

## Usage in SET Backend

### Test Environment (src/env_test/Dockerfile)

```dockerfile
FROM tsouche/set_backend_testprod:v0.6.0

# Install mongosh for testing/debugging
USER root
RUN apt-get update && apt-get install -y gnupg && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-mongosh && \
    rm -rf /var/lib/apt/lists/*

# Application setup
COPY set_backend /app/set_backend
RUN chmod +x /app/set_backend && \
    chown 1026:100 /app/set_backend

USER thierry
ENV RUST_LOG=debug
CMD ["/app/set_backend"]
```

### Production Environment (src/env_prod/Dockerfile)

```dockerfile
FROM tsouche/set_backend_testprod:v0.6.0

# No mongosh - production doesn't need it
COPY set_backend /app/set_backend
RUN chmod +x /app/set_backend && \
    chown 1026:100 /app/set_backend

USER thierry
ENV RUST_LOG=info
CMD ["/app/set_backend"]
```

## When to Rebuild This Image

Rebuild the base image when:

- ✅ SET Backend version changes (e.g., 0.6.0 → 0.7.0)
- ✅ Ubuntu base needs updating (security patches)
- ✅ Runtime dependencies change
- ❌ Application code changes (just rebuild test/prod containers)
- ❌ Configuration changes (use environment variables)

## Updating Deployment Scripts

After rebuilding with a new version, update the test/prod Dockerfiles:

```bash
# src/env_test/Dockerfile
FROM tsouche/set_backend_testprod:v0.7.0

# src/env_prod/Dockerfile
FROM tsouche/set_backend_testprod:v0.7.0
```

## Troubleshooting

**Cannot find Cargo.toml**: Specify version explicitly: `./build_and_push_on_nas.sh 0.6.0`
**SSH connection fails**: Check NAS is accessible at `100.100.10.1:5522`
**Build fails on NAS**: SSH to NAS and check Docker is running
**DockerHub login fails**: Verify your DockerHub credentials are correct

## Useful Commands

```bash
# Check image on NAS
ssh -p 5522 thierry@100.100.10.1 "sudo /usr/local/bin/docker images | grep set_backend_testprod"

# Pull image locally
docker pull tsouche/set_backend_testprod:v0.6.0

# Test image interactively
docker run -it tsouche/set_backend_testprod:v0.6.0 bash
```

---
**Last Updated**: 2025-01-19
