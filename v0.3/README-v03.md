# Generic Rust Development Environment - Version 0.3

A fully configurable containerized Rust development environment with .env-based customization, optimized for Windows 11 and Linux systems.

> **Version:** 0.3  
> **Last Updated:** December 2024  
> **Key Feature:** Complete .env configuration support for maximum flexibility

## 🎯 Overview

This project provides a complete, customizable development environment featuring:

- **Flexible Configuration** - Customize all settings via `.env` file
- **Generic Design** - Not tied to any specific project or naming convention
- **VS Code Integration** - Full Remote-SSH support with configurable ports
- **Ubuntu 22.04 Container** - Isolated Linux development environment via Docker
- **Rust Toolchain** - Latest stable Rust with cargo, rustc, and development tools
- **MongoDB Database** - Dedicated database container with custom naming
- **SSH Access** - Secure key-based authentication with configurable ports
- **MongoDB Express** - Web-based database management interface

### What's New in v0.3

✨ **Environment Variable Configuration** - All settings customizable via `.env` file  
✨ **Generic Naming** - Default names changed from project-specific to generic  
✨ **Port Flexibility** - Configure all port mappings without editing docker-compose  
✨ **Database Customization** - Configure database name, user, collections via .env  
✨ **Multi-Project Support** - Easily maintain multiple configurations

### Benefits

✅ **Fully Customizable**: Change project names, ports, database settings without editing code  
✅ **Isolated & Reproducible**: Containerized setup with version control  
✅ **Multi-Environment**: Run multiple configurations side-by-side  
✅ **Team-Friendly**: Share .env.example, customize locally  
✅ **NAS Compatible**: User/group ID mapping for network storage

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Configuration](#configuration)
3. [Architecture](#architecture)
4. [File Descriptions](#file-descriptions)
5. [Detailed Setup Guide](#detailed-setup-guide)
6. [Usage](#usage)
7. [Customization Examples](#customization-examples)
8. [Troubleshooting](#troubleshooting)
9. [Migration from v0.2](#migration-from-v02)

---

## 🚀 Quick Start

### Basic Setup (Uses Defaults)

```bash
# 1. Clone/navigate to v0.3 directory
cd v0.3

# 2. Copy environment template (optional - defaults work out of box)
cp .env.example .env

# 3. Generate SSH key pair
ssh-keygen -t ed25519 -f rust_dev_key -N ""

# 4. Run deployment script
# For PowerShell (Windows):
.\deploy-v03.ps1

# For Bash (Linux/Mac):
./deploy-v03.sh

# 5. Connect via VS Code Remote-SSH to localhost:2222
```

### Custom Configuration Setup

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env file with your preferences
# Example customizations:
#   PROJECT_NAME=my_awesome_app
#   SSH_PORT=2223
#   DB_NAME=my_app_database

# 3. Generate SSH key pair
ssh-keygen -t ed25519 -f rust_dev_key -N ""

# 4. Run deployment script
./deploy-v03.sh  # or deploy-v03.ps1 on Windows

# 5. Connect via VS Code Remote-SSH to localhost:<your_SSH_PORT>
```

---

## ⚙️ Configuration

### Environment Variables

All configuration is done via the `.env` file. Copy `.env.example` to `.env` and customize as needed.

#### Essential Settings

```bash
# Project Configuration
PROJECT_NAME=rust_project           # Name of your project
PROJECT_DIR=rust_project            # Directory name for source code
USERNAME=rustdev                    # Container username

# Port Configuration
SSH_PORT=2222                       # SSH port for VS Code Remote
APP_PORT=8080                       # Your application port
MONGO_PORT=27017                    # MongoDB port
MONGO_EXPRESS_PORT=8081             # Mongo Express web UI port

# Database Configuration
DB_NAME=rust_app_db                 # Database name
DB_USER=app_user                    # Database username
DB_PASSWORD=SecurePassword123       # Database password
```

#### Default Values

If you don't create a `.env` file, these defaults are used:

- **Project Directory**: `rust_project`
- **Database Name**: `rust_app_db`
- **Database User**: `app_user`
- **SSH Port**: `2222`
- **Application Port**: `8080`
- **MongoDB Port**: `27017`
- **Mongo Express Port**: `8081`

#### Complete Configuration

The `.env.example` file contains 85+ configuration options including:

- Container names
- Network settings
- Volume configurations
- MongoDB collections
- User/group IDs (for NAS)
- Advanced Docker settings

**View full configuration**: See `.env.example` for all available options and detailed comments.

---

## 🏗️ Architecture

### Container Structure

```
┌──────────────────────────────────────────────────────┐
│              Windows 11 / Linux Host                 │
│                                                      │
│  ┌────────────────┐          ┌───────────────────┐   │
│  │   VS Code      │ SSH      │  Docker           │   │
│  │   (IDE)        │─────────>│                   │   │
│  └────────────────┘ :$PORT   │  ┌─────────────┐  │   │
│                              │  │  rust-dev   │  │   │
│  ┌────────────────┐          │  │  Container  │  │   │
│  │  Web Browser   │ :$MEXPR  │  └──────┬──────┘  │   │
│  │  (Mongo UI)    │<─────────│         │         │   │
│  └────────────────┘          │         │ Network │   │
│                              │  ┌──────▼──────┐  │   │
│  ┌────────────────┐          │  │  MongoDB    │  │   │
│  │  Source Code   │<────────>│  │  Container  │  │   │
│  │  (./$PROJECT)  │ Volume   │  └─────────────┘  │   │
│  └────────────────┘          └───────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### Directory Layout

```
v0.3/                               # Version 0.3 directory
├── dockerfile.v0.3                 # Ubuntu + Rust + SSH configuration
├── docker-compose-v03.yml          # Multi-container orchestration
```

**Path Mapping:**

| Purpose           | Host System                 | Linux Container            |
|-------------------|-----------------------------|----------------------------|
| Project root      | ./v0.3/                     | N/A                        |
| Rust source code  | ./v0.3/$PROJECT_DIR/        | /workspace/$PROJECT_DIR/   |
| SSH keys          | ~/.ssh/ or %USERPROFILE%\\.ssh\ | /home/$USERNAME/.ssh/  |

---

## 📄 File Descriptions

### Configuration Files

#### `.env.example`
Template environment configuration file with all available settings documented. Copy to `.env` and customize.

**Contents:**
- 85+ configuration variables
- Detailed comments for each setting
- Sensible defaults for quick start
- Grouped by category (project, ports, database, etc.)

#### `.env` (You Create This)
Your local configuration file (not version controlled). Contains your custom settings.

**Example:**
```bash
PROJECT_NAME=my_game
PROJECT_DIR=game_backend
SSH_PORT=2223
DB_NAME=game_database
DB_USER=game_user
```

### Docker Configuration Files

#### `dockerfile.v0.3`
Defines the development container image with Ubuntu 22.04, Rust toolchain, SSH server, and MongoDB client.

**Key Features:**
- Ubuntu 22.04 LTS base
- Rust stable toolchain via rustup
- OpenSSH server on port 22 (mapped externally via $SSH_PORT)
- MongoDB 7.0 client tools
- Configurable user via build args (USER_UID, USER_GID, USERNAME)
- Includes authorized_keys for SSH authentication

#### `docker-compose-v03.yml`
Multi-container orchestration configuration. **Fully parameterized with .env variables.**

**Services:**
1. **rust-dev** - Development container with Rust and SSH
2. **mongo-db** - MongoDB 7.0 database server
3. **mongo-express** - Web UI for MongoDB management

**Key Features:**
- All settings read from .env file
- Container names: `${CONTAINER_RUST_DEV:-rust-dev-container}`
- Ports: `${SSH_PORT:-2222}:22`
- Volumes: Cargo cache, target cache, MongoDB data
- Network: Shared bridge network for inter-container communication

### Deployment Scripts

#### `deploy-v03.sh` (Bash)
Automated deployment script for Linux/Mac/WSL.

**Features:**
- Loads `.env` if present, uses defaults otherwise
- Creates project directory structure
- Generates SSH key pair if not exists
- Creates MongoDB initialization script from .env variables
- Generates sample Rust project
- Builds and starts containers
- Displays configuration and service URLs

#### `deploy-v03.ps1` (PowerShell)
Automated deployment script for Windows PowerShell.

**Features:**
- Same functionality as Bash script
- Color-coded output for better readability
- Windows-specific path handling
- VS Code SSH configuration helper

---

## 🔧 Detailed Setup Guide

### Prerequisites

#### Windows Users

1. **Windows 11** (tested on Pro/Enterprise, Home should work)
2. **Docker Desktop for Windows** (version 4.x or later)
   - WSL 2 backend enabled
   - Resources: 4GB RAM minimum (8GB recommended)
3. **VS Code** with Remote-SSH extension
4. **PowerShell** 5.1 or later (included in Windows)

#### Linux Users

1. **Linux Distribution** (Ubuntu, Debian, Fedora, etc.)
2. **Docker Engine** (version 20.10 or later)
3. **Docker Compose** (version 2.x or later)
4. **VS Code** with Remote-SSH extension
5. **Bash** (usually pre-installed)

### Step 1: Prepare Environment

```bash
# Navigate to v0.3 directory
cd /path/to/dev_environment/v0.3

# Copy environment template
cp .env.example .env

# (Optional) Edit .env to customize your setup
nano .env  # or use any text editor
```

### Step 2: Generate SSH Keys

The deployment scripts will generate SSH keys automatically, but you can do it manually:

```bash
# Generate ED25519 key pair (recommended)
ssh-keygen -t ed25519 -f rust_dev_key -N ""

# Or generate RSA key pair (alternative)
ssh-keygen -t rsa -b 4096 -f rust_dev_key -N ""
```

This creates:
- `rust_dev_key` - Private key (keep secure)
- `rust_dev_key.pub` - Public key (deployed to container)

### Step 3: Run Deployment Script

#### Windows (PowerShell)

```powershell
# Run deployment script
.\deploy-v03.ps1

# The script will:
# 1. Load your .env configuration
# 2. Create project structure
# 3. Generate SSH keys (if needed)
# 4. Create MongoDB initialization script
# 5. Build Docker images
# 6. Start containers
# 7. Display service URLs and configuration
```

#### Linux/Mac (Bash)

```bash
# Make script executable
chmod +x deploy-v03.sh

# Run deployment script
./deploy-v03.sh

# The script will:
# 1. Load your .env configuration
# 2. Create project structure
# 3. Generate SSH keys (if needed)
# 4. Create MongoDB initialization script
# 5. Build Docker images
# 6. Start containers
# 7. Display service URLs and configuration
```

### Step 4: Configure VS Code Remote-SSH

#### Add SSH Host Configuration

**Windows:** Edit `C:\Users\<YourUsername>\.ssh\config`  
**Linux/Mac:** Edit `~/.ssh/config`

Add this configuration (adjust port if you changed SSH_PORT):

```
Host rust-dev-container
    HostName localhost
    Port 2222
    User rustdev
    IdentityFile /path/to/v0.3/rust_dev_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Note:** Replace `/path/to/v0.3/rust_dev_key` with the absolute path to your private key.

#### Connect via VS Code

1. Open VS Code
2. Install "Remote - SSH" extension (if not installed)
3. Press `F1` or `Ctrl+Shift+P`
4. Type "Remote-SSH: Connect to Host..."
5. Select "rust-dev-container"
6. Open folder: `/workspace/rust_project` (or your custom $PROJECT_DIR)

---

## 💻 Usage

### Accessing Services

After deployment, access these services (ports shown are defaults):

| Service | URL | Credentials |
|---------|-----|-------------|
| SSH (VS Code) | `localhost:2222` | Key-based (rust_dev_key) |
| Application | `http://localhost:8080` | N/A |
| MongoDB | `localhost:27017` | user: app_user, pwd: from .env |
| Mongo Express | `http://localhost:8081` | user: dev, pwd: dev123 |

**Custom Ports:** If you changed ports in `.env`, use your configured values.

### Working with Rust Projects

#### Inside VS Code (Connected via Remote-SSH)

```bash
# Navigate to project directory
cd /workspace/rust_project  # or your custom $PROJECT_DIR

# Build project
cargo build

# Run project
cargo run

# Run tests
cargo test

# Add dependencies
cargo add <package_name>
```

#### MongoDB Access

**Via Mongo Express (Web UI):**
1. Open browser: `http://localhost:8081` (or your $MONGO_EXPRESS_PORT)
2. Login: user `dev`, password `dev123`
3. Browse databases, collections, documents

**Via MongoDB Shell (Inside Container):**
```bash
# Connect to container
docker compose exec rust-dev bash

# Connect to MongoDB
mongosh mongodb://mongo-db:27017/rust_app_db -u app_user -p SecurePassword123

# Or use configured values
mongosh mongodb://mongo-db:27017/$DB_NAME -u $DB_USER -p $DB_PASSWORD
```

**Via MongoDB Compass (GUI Application):**
```
Connection String: mongodb://app_user:SecurePassword123@localhost:27017/rust_app_db
```

### Docker Commands

```bash
# View running containers
docker compose ps

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f rust-dev

# Restart services
docker compose restart

# Stop services
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v

# Rebuild images
docker compose build --no-cache

# Start services
docker compose up -d
```

---

## 🎨 Customization Examples

### Example 1: Game Development Environment

```bash
# .env
PROJECT_NAME=dungeon_crawler
PROJECT_DIR=game_backend
SSH_PORT=2222
APP_PORT=8080
DB_NAME=game_database
DB_USER=game_dev
DB_PASSWORD=GameDev2024!
COLLECTION_1=players
COLLECTION_2=levels
COLLECTION_3=items
```

**Result:**
- Project directory: `game_backend/`
- Database: `game_database`
- Collections: `players`, `levels`, `items`

### Example 2: Multiple Projects Side-by-Side

**Project A Configuration:**
```bash
# project_a/.env
PROJECT_NAME=project_a
PROJECT_DIR=project_a_backend
SSH_PORT=2222
APP_PORT=8080
MONGO_PORT=27017
MONGO_EXPRESS_PORT=8081
DB_NAME=project_a_db
CONTAINER_RUST_DEV=project-a-rust-dev
CONTAINER_MONGODB=project-a-mongodb
```

**Project B Configuration:**
```bash
# project_b/.env
PROJECT_NAME=project_b
PROJECT_DIR=project_b_backend
SSH_PORT=2223           # Different port!
APP_PORT=8081           # Different port!
MONGO_PORT=27018        # Different port!
MONGO_EXPRESS_PORT=8082 # Different port!
DB_NAME=project_b_db
CONTAINER_RUST_DEV=project-b-rust-dev
CONTAINER_MONGODB=project-b-mongodb
```

**Result:** Both projects run simultaneously without conflicts.

### Example 3: NAS/Network Storage

If your code is on a NAS with specific user/group IDs:

```bash
# .env
USER_UID=1001      # Your NAS user ID
USER_GID=1001      # Your NAS group ID
USERNAME=nas_user  # Your NAS username
```

This ensures file permissions work correctly between container and NAS.

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error:** `Error starting userland proxy: listen tcp 0.0.0.0:2222: bind: address already in use`

**Solution:**
Change port in `.env`:
```bash
SSH_PORT=2223  # or any available port
```

Then redeploy:
```bash
docker compose down
./deploy-v03.sh  # or deploy-v03.ps1
```

#### 2. .env File Not Loading

**Symptoms:** Default values used despite having .env file

**Solution:**
- Ensure `.env` file is in the same directory as `docker-compose-v03.yml`
- Check for syntax errors in `.env` (no spaces around `=`)
- Correct: `PROJECT_NAME=myproject`
- Wrong: `PROJECT_NAME = myproject`

#### 3. SSH Connection Refused

**Symptoms:** VS Code can't connect via SSH

**Checklist:**
- Container is running: `docker compose ps`
- SSH port is correct in VS Code config
- Private key path is correct
- Private key has correct permissions: `chmod 600 rust_dev_key` (Linux/Mac)

#### 4. MongoDB Connection Issues

**Symptoms:** Can't connect to MongoDB from Rust app

**Solution:**
Inside container, use hostname `mongo-db` not `localhost`:
```rust
let client = Client::with_uri_str("mongodb://mongo-db:27017").await?;
```

**From host machine**, use `localhost` and the configured $MONGO_PORT.

#### 5. Permission Denied Errors

**Symptoms:** Can't write files in project directory

**Solution:**
Check USER_UID and USER_GID in `.env` match your host user:
```bash
# Find your UID/GID (Linux/Mac)
id -u  # UID
id -g  # GID

# Update .env
USER_UID=1000
USER_GID=1000
```

Rebuild container:
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Debugging Commands

```bash
# Check if .env is loaded
docker compose config  # Shows resolved configuration

# View container logs
docker compose logs rust-dev

# Get shell in container
docker compose exec rust-dev bash

# Check environment variables inside container
docker compose exec rust-dev env | grep DB_NAME

# Test MongoDB connection
docker compose exec rust-dev mongosh mongodb://mongo-db:27017 -u app_user -p SecurePassword123
```

---

## 📦 Migration from v0.2

### Key Differences

| Aspect | v0.2 | v0.3 |
|--------|------|------|
| Configuration | Hardcoded in files | .env file based |
| Project Name | set_backend (fixed) | rust_project (configurable) |
| Database Name | set_game_db (fixed) | rust_app_db (configurable) |
| Database User | set_app_user (fixed) | app_user (configurable) |
| Collections | games, players, scores | items, users, data (configurable) |
| File Names | *-v02.yml | *-v03.yml |

### Migration Steps

1. **Copy your custom settings:**
   ```bash
   # Create .env from template
   cp .env.example .env
   ```

2. **Map v0.2 settings to .env:**
   ```bash
   # If you customized v0.2, translate to .env:
   # v0.2: set_backend → .env: PROJECT_DIR=set_backend
   # v0.2: set_game_db → .env: DB_NAME=set_game_db
   # v0.2: port 2222 → .env: SSH_PORT=2222
   ```

3. **Copy your project code:**
   ```bash
   cp -r ../v0.2/set_backend/* ./rust_project/
   ```

4. **Update connection strings in code:**
   ```rust
   // v0.2 (hardcoded)
   let uri = "mongodb://mongo-db:27017/set_game_db";
   
   // v0.3 (use environment variable)
   let db_name = env::var("DB_NAME").unwrap_or_else(|_| "rust_app_db".to_string());
   let uri = format!("mongodb://mongo-db:27017/{}", db_name);
   ```

5. **Deploy v0.3:**
   ```bash
   ./deploy-v03.sh  # or deploy-v03.ps1
   ```

### Preserving v0.2 Names

To keep using v0.2 names in v0.3:

```bash
# .env
PROJECT_DIR=set_backend
DB_NAME=set_game_db
DB_USER=set_app_user
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores
```

This allows gradual migration while maintaining compatibility.

---

## 📚 Additional Resources

### Files to Review

- **`.env.example`** - Complete list of all configuration options
- **`docker-compose-v03.yml`** - See how .env variables are used
- **`dockerfile.v0.3`** - Understand container image
- **`authorized_keys`** - SSH public key for container access
- **`deploy-v03.sh` / `deploy-v03.ps1`** - Deployment automation details

### Useful Links

- [Rust Documentation](https://doc.rust-lang.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [VS Code Remote-SSH](https://code.visualstudio.com/docs/remote/ssh)

---

## 📝 Version Information

**Version:** 0.3  
**Release Date:** December 2024  
**Previous Version:** 0.2  

**Major Changes:**
- ✨ Complete .env configuration support (85+ variables)
- ✨ Generic naming conventions (not project-specific)
- ✨ Port flexibility (all ports configurable)
- ✨ Database customization (name, user, collections)
- ✨ Multi-environment support (run multiple configs)
- 🔧 Updated deployment scripts with .env loading
- 📖 Comprehensive documentation with examples

**Compatibility:** Backward compatible with v0.2 by customizing .env to use v0.2 names.

---

## 🤝 Contributing

To customize for your needs:

1. Copy `.env.example` to `.env`
2. Modify settings as needed
3. Test deployment: `./deploy-v03.sh`
4. Share `.env.example` with team (don't commit `.env`)

---

## 📄 License

See LICENSE file in repository root.

---

**Questions?** Check the [Troubleshooting](#troubleshooting) section or review `.env.example` for configuration options.
