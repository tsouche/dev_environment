# Rust Development Environment for Windows 11 - Version 0.2

A containerized Rust development environment optimized for Windows 11, combining the convenience of VS Code on Windows with the power of a Linux development environment.

> **Version:** 0.2  
> **Last Updated:** November 2025

## 🎯 Overview

This project provides a complete, version-controlled development environment featuring:

- **VS Code on Windows 11** - Your familiar IDE with full Remote-SSH integration
- **Ubuntu 22.04 Container** - Isolated Linux development environment via Docker Desktop
- **Rust Toolchain** - Latest stable Rust with cargo, rustc, and development tools
- **MongoDB Database** - Dedicated database container for data persistence
- **SSH Access** - Secure key-based authentication for remote development
- **MongoDB Express** - Web-based database management interface

### Benefits

✅ **Best of Both Worlds**: Windows productivity tools + Linux development environment  
✅ **Isolated & Reproducible**: Containerized setup with version control  
✅ **Full-Stack Ready**: Backend development with database integration  
✅ **Team-Friendly**: Consistent environment across all developers  
✅ **NAS Compatible**: User/group ID mapping for network storage
## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [File Descriptions](#file-descriptions)
5. [Detailed Setup Guide](#detailed-setup-guide)
6. [Usage](#usage)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Configuration](#advanced-configuration)

---

## 🏗️ Architecture

### Container Structure

```
┌─────────────────────────────────────────────────────┐
│              Windows 11 Laptop                       │
│                                                      │
│  ┌────────────────┐         ┌──────────────────┐   │
│  │   VS Code      │ SSH     │  Docker Desktop   │   │
│  │   (IDE)        │────────▶│                   │   │
│  └────────────────┘ :2222   │  ┌─────────────┐  │   │
│                              │  │  rust-dev   │  │   │
│  ┌────────────────┐          │  │  Container  │  │   │
│  │  Web Browser   │ :8081    │  └──────┬──────┘  │   │
│  │  (Mongo UI)    │◀─────────│         │         │   │
│  └────────────────┘          │         │ Network │   │
│                              │  ┌──────▼──────┐  │   │
│  ┌────────────────┐          │  │  MongoDB    │  │   │
│  │  Source Code   │◀────────▶│  │  Container  │  │   │
│  │  (./set_backend)│ Volume  │  └─────────────┘  │   │
│  └────────────────┘          └──────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Directory Layout

```
v0.2/                               # Version 0.2 directory
├── dockerfile.v0.2                 # Ubuntu + Rust + SSH configuration
├── docker-compose-v02.yml          # Multi-container orchestration
├── deploy-v02.sh                   # Bash deployment script
├── deploy-v02.ps1                  # PowerShell deployment script
├── documentation-v02.md            # This documentation file
├── authorized_keys                 # SSH public key (created during setup)
├── set_backend/                    # Your Rust project code
│   ├── Cargo.toml                  # Rust dependencies
│   └── src/
│       └── main.rs                 # Application entry point
└── docker/
    └── mongo-init/                 # MongoDB initialization scripts
        └── 01-init-db.js
```

**Path Mapping:**

| Purpose           | Windows Host                | Linux Container      |
|-------------------|-----------------------------|----------------------|
| Project root      | .\v0.2\                     | N/A                  |
| Rust source code  | .\v0.2\set_backend\         | /workspace/set_backend/ |
| SSH keys          | %USERPROFILE%\\.ssh\        | /home/rustdev/.ssh/  |

---

## ✅ Prerequisites

### Required Software

1. **Windows 11** (tested on Pro/Enterprise, Home should work)
2. **Docker Desktop for Windows** (version 4.x or later)
   - WSL 2 backend enabled
   - Running with adequate resources (4GB RAM minimum, 8GB recommended)
3. **VS Code** (latest stable version)
   - Extension: **Remote - SSH** (ms-vscode-remote.remote-ssh)
   - Extension: **rust-analyzer** (rust-lang.rust-analyzer)
4. **SSH Client** (built into Windows 10/11)
5. **PowerShell 5.1+** or **Git Bash** (for running deployment scripts)

### SSH Key Pair

Generate an SSH key if you don't have one:

```powershell
# In PowerShell or CMD
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press Enter to accept default location (`C:\Users\YourName\.ssh\id_ed25519`).

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

**For PowerShell (Windows):**

```powershell
# Navigate to project directory
cd path\to\dev_environment\v0.2

# Run deployment script
.\deploy-v02.ps1
```

**For Git Bash/WSL:**

```bash
# Navigate to project directory
cd /path/to/dev_environment/v0.2

# Make script executable
chmod +x deploy-v02.sh

# Run deployment script
./deploy-v02.sh
```

The script will:
- ✅ Verify Docker Desktop is running
- ✅ Create required directories
- ✅ Copy your SSH public key
- ✅ Generate MongoDB initialization scripts
- ✅ Create sample Rust project
- ✅ Build Docker images
- ✅ Start all containers
- ✅ Display connection information

### Option 2: Manual Deployment

See [Detailed Setup Guide](#detailed-setup-guide) below.

---

## 📄 File Descriptions

### 1. `dockerfile.v0.2`

**Purpose:** Defines the Rust development container image based on Ubuntu 22.04.

**Key Features:**
- **Base Image:** Ubuntu 22.04 LTS
- **System Packages:** 
  - Build tools (gcc, make, pkg-config)
  - SSL libraries (libssl-dev)
  - Git, vim, nano, htop
  - MongoDB client tools
  - SSH server (openssh-server)
- **User Configuration:**
  - Non-root user: `rustdev` (UID: 1026, GID: 110)
  - Sudo access without password
  - Compatible with NAS user/group IDs
- **Rust Toolchain:**
  - Installed via rustup for user `rustdev`
  - Stable channel by default
  - Cargo, rustc, and standard tools
- **SSH Configuration:**
  - Key-based authentication only (no passwords)
  - Root login disabled
  - Port 22 exposed (mapped to host 2222)
- **MongoDB Environment:**
  - Connection URI pre-configured
  - Ready for database integration

**Build Context:** Expects `authorized_keys` file in the same directory.

### 2. `docker-compose-v02.yml`

**Purpose:** Orchestrates multiple containers and their networking.

**Services:**

#### `rust-dev` (Development Container)
- **Build:** Uses `dockerfile.v0.2`
- **Ports:**
  - `2222:22` - SSH access
  - `8080:8080` - Application server
- **Volumes:**
  - `./set_backend:/workspace/set_backend` - Source code
  - `cargo-cache` - Rust package cache (persistent)
  - `target-cache` - Build artifacts cache (persistent)
- **Environment:** MongoDB connection details
- **Network:** Connected to `dev-network`

#### `mongo-db` (Database)
- **Image:** MongoDB 7.0 (Jammy)
- **Port:** `27017:27017`
- **Credentials:**
  - Root: admin/admin123
  - App User: set_app_user/set_app_password
- **Volumes:**
  - `mongodb-data` - Persistent database storage
  - `./docker/mongo-init` - Initialization scripts
- **Database:** `set_game_db` (created on first run)

#### `mongo-express` (Database UI)
- **Image:** Mongo Express 1.0.0-alpha
- **Port:** `8081:8081`
- **Credentials:** dev/dev123
- **Purpose:** Web-based MongoDB management interface

**Networks:**
- `dev-network` (bridge) - Allows inter-container communication

### 3. `deploy-v02.sh` / `deploy-v02.ps1`

**Purpose:** Automated deployment scripts for Bash and PowerShell.

**Functions:**
1. **Pre-flight Checks:**
   - Verify Docker Desktop is installed and running
   - Check Docker Compose availability
2. **Setup:**
   - Create directory structure
   - Copy SSH public key to `authorized_keys`
   - Generate MongoDB initialization script
   - Create sample Rust project (if not exists)
3. **Deployment:**
   - Build Docker images
   - Start containers in detached mode
   - Display service URLs and connection info
4. **Configuration Help:**
   - Provide VS Code SSH configuration snippet
   - Display next steps and useful commands

**Output:** Running containers with all services accessible.

---

## 📖 Detailed Setup Guide

### Step 1: Prepare Your Environment

1. **Clone or Download** this repository:
   ```powershell
   git clone <repository-url> dev_environment
   cd dev_environment/v0.2
   ```

2. **Ensure Docker Desktop is Running:**
   - Open Docker Desktop
   - Wait for "Docker Desktop is running" status
   - Check WSL 2 integration is enabled (Settings → Resources → WSL Integration)

3. **Verify SSH Key Exists:**
   ```powershell
   # Check for key
   Test-Path $env:USERPROFILE\.ssh\id_ed25519.pub
   
   # If False, generate one:
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

### Step 2: Deploy the Environment

#### Using Deployment Script (Recommended)

Run the deployment script for your platform:

**PowerShell:**
```powershell
.\deploy-v02.ps1
```

**Git Bash:**
```bash
chmod +x deploy-v02.sh
./deploy-v02.sh
```

The script handles everything automatically. Skip to Step 3.

#### Manual Deployment

If you prefer manual control:

**A. Create Required Directories:**
```powershell
New-Item -ItemType Directory -Force set_backend\src
New-Item -ItemType Directory -Force docker\mongo-init
```

**B. Copy SSH Public Key:**
```powershell
Copy-Item $env:USERPROFILE\.ssh\id_ed25519.pub .\authorized_keys
```

**C. Create MongoDB Init Script:**

Create `docker/mongo-init/01-init-db.js`:
```javascript
db = db.getSiblingDB('set_game_db');

db.createUser({
    user: 'set_app_user',
    pwd: 'set_app_password',
    roles: [{ role: 'readWrite', db: 'set_game_db' }]
});

db.createCollection('games');
db.createCollection('players');
db.createCollection('scores');

print('Database initialized successfully');
```

**D. Create Sample Rust Project:**

`set_backend/Cargo.toml`:
```toml
[package]
name = "set_backend"
version = "0.1.0"
edition = "2021"

[dependencies]
mongodb = "2.8"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
```

`set_backend/src/main.rs`:
```rust
use mongodb::{Client, options::ClientOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("SET Game Backend - Development Environment");
    
    let mongodb_uri = std::env::var("MONGODB_URI")
        .unwrap_or_else(|_| "mongodb://localhost:27017".to_string());
    
    println!("Connecting to MongoDB at: {}", mongodb_uri);
    
    let client_options = ClientOptions::parse(&mongodb_uri).await?;
    let client = Client::with_options(client_options)?;
    
    let db_names = client.list_database_names(None, None).await?;
    println!("Available databases:");
    for name in db_names {
        println!("  - {}", name);
    }
    
    println!("\nMongoDB connection successful!");
    Ok(())
}
```

**E. Build and Start Containers:**
```powershell
docker compose build
docker compose up -d
```

**F. Verify Deployment:**
```powershell
docker compose ps
```

All services should show "Up" status.

### Step 3: Configure VS Code

1. **Open VS Code**

2. **Install Required Extensions:**
   - Press `Ctrl+Shift+X`
   - Search and install:
     - **Remote - SSH** (ms-vscode-remote.remote-ssh)
     - **rust-analyzer** (rust-lang.rust-analyzer)

3. **Configure SSH Connection:**
   - Press `Ctrl+Shift+P`
   - Type: `Remote-SSH: Open Configuration File`
   - Select: `C:\Users\YourName\.ssh\config`
   - Add this configuration:

```ssh-config
Host rust-dev-container
    HostName localhost
    Port 2222
    User rustdev
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

   - Save the file (`Ctrl+S`)

4. **Connect to Container:**
   - Press `Ctrl+Shift+P`
   - Type: `Remote-SSH: Connect to Host`
   - Select: `rust-dev-container`
   - Wait for connection (first time may take longer)
   - Look for green indicator in bottom-left: `SSH: rust-dev-container`

5. **Open Workspace:**
   - Once connected: File → Open Folder
   - Navigate to: `/workspace/set_backend`
   - Click "OK"

6. **Install Remote Extensions:**
   - Press `Ctrl+Shift+X`
   - Find "rust-analyzer"
   - Click "Install in SSH: rust-dev-container"
   - Optionally install:
     - **Cargo** (panicbit.cargo)
     - **Even Better TOML** (tamasfe.even-better-toml)
     - **GitLens** (eamodio.gitlens)

### Step 4: Verify the Setup

1. **Open Terminal in VS Code:**
   - Press `` Ctrl+` `` (backtick)
   - You should see: `rustdev@<container-id>:/workspace/set_backend$`

2. **Check Rust Installation:**
   ```bash
   rustc --version
   cargo --version
   rustup show
   ```

3. **Build Sample Project:**
   ```bash
   cargo build
   ```

4. **Run Sample Project:**
   ```bash
   cargo run
   ```

   Expected output:
   ```
   SET Game Backend - Development Environment
   Connecting to MongoDB at: mongodb://mongo-db:27017/set_game_db
   Available databases:
     - admin
     - config
     - local
     - set_game_db
   
   MongoDB connection successful!
   ```

5. **Access MongoDB Express:**
   - Open browser: http://localhost:8081
   - Login: `dev` / `dev123`
   - Verify `set_game_db` database exists

---

## 💻 Usage

### Daily Workflow

1. **Start Environment:**
   ```powershell
   docker compose up -d
   ```

2. **Connect VS Code:**
   - `Ctrl+Shift+P` → `Remote-SSH: Connect to Host` → `rust-dev-container`

3. **Develop:**
   - Edit code in VS Code
   - Run `cargo build`, `cargo test`, `cargo run` in terminal
   - Changes persist on Windows host in `./set_backend`

4. **Stop Environment:**
   ```powershell
   docker compose down
   ```

### Common Commands

**Container Management:**
```powershell
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart services
docker compose restart

# View logs
docker compose logs -f rust-dev

# Access container shell
docker compose exec rust-dev bash
```

**Rust Development:**
```bash
# Inside container or VS Code terminal

# Build project
cargo build

# Build optimized release
cargo build --release

# Run project
cargo run

# Run tests
cargo test

# Check code without building
cargo check

# Lint with clippy
cargo clippy

# Format code
cargo fmt

# Update dependencies
cargo update
```

**MongoDB Operations:**
```bash
# Inside container

# Connect to MongoDB
mongosh mongodb://mongo-db:27017/set_game_db

# Connect with authentication
mongosh mongodb://set_app_user:set_app_password@mongo-db:27017/set_game_db
```

### Accessing Services

| Service          | URL/Command                 | Credentials            |
|------------------|-----------------------------|------------------------|
| SSH Access       | `localhost:2222`            | Key-based auth         |
| Application      | `http://localhost:8080`     | N/A                    |
| MongoDB          | `localhost:27017`           | set_app_user/set_app_password |
| Mongo Express    | `http://localhost:8081`     | dev/dev123             |
| Container Shell  | `docker compose exec rust-dev bash` | -          |

---

## 🔧 Troubleshooting

### Cannot Connect to Container via SSH

**Problem:** VS Code fails to connect or hangs.

**Solutions:**
1. Verify container is running:
   ```powershell
   docker compose ps
   ```
   Status should show "Up".

2. Check SSH service inside container:
   ```powershell
   docker compose exec rust-dev service ssh status
   ```

3. Verify authorized_keys file exists and has correct permissions:
   ```powershell
   docker compose exec rust-dev ls -la /home/rustdev/.ssh/
   ```

4. Test SSH connection manually:
   ```powershell
   ssh -p 2222 rustdev@localhost -v
   ```

5. Rebuild container if key was added after build:
   ```powershell
   docker compose down
   docker compose build --no-cache rust-dev
   docker compose up -d
   ```

### MongoDB Connection Fails

**Problem:** Rust app cannot connect to MongoDB.

**Solutions:**
1. Verify MongoDB is running:
   ```powershell
   docker compose ps mongo-db
   ```

2. Check network connectivity from rust-dev:
   ```powershell
   docker compose exec rust-dev ping mongo-db
   ```

3. Test MongoDB connection:
   ```powershell
   docker compose exec rust-dev mongosh mongodb://mongo-db:27017/set_game_db
   ```

4. View MongoDB logs:
   ```powershell
   docker compose logs mongo-db
   ```

5. Verify environment variables in container:
   ```powershell
   docker compose exec rust-dev env | grep MONGODB
   ```

### Cargo Build Fails

**Problem:** Dependencies won't download or build errors occur.

**Solutions:**
1. Check internet connectivity from container:
   ```powershell
   docker compose exec rust-dev ping -c 3 crates.io
   ```

2. Clear cargo cache and retry:
   ```bash
   # Inside container
   cargo clean
   rm -rf ~/.cargo/registry
   cargo build
   ```

3. Update Rust toolchain:
   ```bash
   rustup update stable
   ```

4. Check disk space:
   ```powershell
   docker system df
   ```

### Port Already in Use

**Problem:** `Error: port 2222 is already allocated`.

**Solutions:**
1. Find process using the port:
   ```powershell
   netstat -ano | findstr :2222
   ```

2. Stop conflicting service or change port in `docker-compose-v02.yml`:
   ```yaml
   ports:
     - "2223:22"  # Changed from 2222
   ```

3. Update VS Code SSH config to match new port.

### Permission Denied Errors

**Problem:** Cannot write files or permission errors in /workspace.

**Solutions:**
1. Verify volume permissions:
   ```powershell
   docker compose exec rust-dev ls -la /workspace
   ```

2. Fix ownership if needed:
   ```powershell
   docker compose exec rust-dev sudo chown -R rustdev:rustdevteam /workspace
   ```

3. Check UID/GID match in Dockerfile (if using NAS):
   - Edit `dockerfile.v0.2` ARG values
   - Rebuild: `docker compose build --no-cache`

### Docker Desktop Issues

**Problem:** Docker Desktop won't start or is slow.

**Solutions:**
1. Restart Docker Desktop
2. Check WSL 2 integration:
   - Docker Desktop → Settings → Resources → WSL Integration
   - Enable integration with your distro
3. Increase resources:
   - Docker Desktop → Settings → Resources
   - Allocate more CPU/Memory (4GB RAM minimum)
4. Clear Docker cache:
   ```powershell
   docker system prune -a --volumes
   ```

### VS Code rust-analyzer Not Working

**Problem:** No code completion or errors not showing.

**Solutions:**
1. Ensure rust-analyzer is installed **in the remote**:
   - Extensions → rust-analyzer → "Install in SSH: rust-dev-container"

2. Reload VS Code window:
   - `Ctrl+Shift+P` → "Developer: Reload Window"

3. Check rust-analyzer output:
   - View → Output → Select "Rust Analyzer Language Server" from dropdown

4. Verify Rust toolchain in terminal:
   ```bash
   rustc --version
   which cargo
   ```

5. Check for conflicting extensions (disable "rls" if installed)

---

## 🔐 Advanced Configuration

### Customizing User/Group IDs

If using network storage (NAS) with specific UID/GID requirements:

1. Edit `dockerfile.v0.2`:
   ```dockerfile
   ARG USER_UID=1026    # Change to your NAS user ID
   ARG USER_GID=110     # Change to your NAS group ID
   ```

2. Rebuild:
   ```powershell
   docker compose build --no-cache rust-dev
   docker compose up -d
   ```

### Adding Rust Tools

Install additional Rust tools inside the container:

```bash
# Connect to container
docker compose exec rust-dev bash

# Install tools
cargo install cargo-watch    # Auto-rebuild on file changes
cargo install cargo-edit     # Manage Cargo.toml from CLI
cargo install cargo-audit    # Security vulnerability scanner
cargo install diesel_cli --no-default-features --features postgres
```

To persist these, add to `dockerfile.v0.2` before CMD:

```dockerfile
USER ${USERNAME}
RUN /home/${USERNAME}/.cargo/bin/cargo install cargo-watch cargo-edit
USER root
```

### Changing Default Ports

Edit `docker-compose-v02.yml`:

```yaml
services:
  rust-dev:
    ports:
      - "2223:22"      # SSH (change 2223 to desired host port)
      - "8080:8080"    # Application (change as needed)
  
  mongo-db:
    ports:
      - "27018:27017"  # MongoDB (change 27018 to desired host port)
```

Update VS Code SSH config to match new SSH port.

### Using Different MongoDB Versions

Edit `docker-compose-v02.yml`:

```yaml
mongo-db:
  image: mongo:6.0-jammy    # Change version here
```

Available versions: https://hub.docker.com/_/mongo/tags

### Persistent Data Management

**Backup MongoDB Data:**
```powershell
docker compose exec mongo-db mongodump --out=/tmp/backup
docker cp set-mongodb:/tmp/backup ./mongodb-backup
```

**Restore MongoDB Data:**
```powershell
docker cp ./mongodb-backup set-mongodb:/tmp/backup
docker compose exec mongo-db mongorestore /tmp/backup
```

**Clean Volumes (⚠️ DELETES ALL DATA):**
```powershell
docker compose down -v
```

### Environment Variables

Add custom environment variables in `docker-compose-v02.yml`:

```yaml
services:
  rust-dev:
    environment:
      - RUST_LOG=debug
      - CUSTOM_VAR=value
      - API_KEY=${API_KEY}  # From host environment
```

Access in Rust:
```rust
let custom_var = std::env::var("CUSTOM_VAR").unwrap();
```

---

## 📚 Additional Resources

### Documentation

- **Rust:** https://doc.rust-lang.org/book/
- **Cargo:** https://doc.rust-lang.org/cargo/
- **MongoDB Rust Driver:** https://www.mongodb.com/docs/drivers/rust/
- **Docker Compose:** https://docs.docker.com/compose/
- **VS Code Remote-SSH:** https://code.visualstudio.com/docs/remote/ssh

### Useful Extensions

- **crates:** Manage Cargo.toml dependencies
- **Error Lens:** Inline error highlighting
- **GitGraph:** Visualize git history
- **Thunder Client:** API testing inside VS Code

---

## 🤝 Contributing

To modify this environment:

1. **Update Dockerfile:** Edit `dockerfile.v0.2`
2. **Test Changes:**
   ```powershell
   docker compose build --no-cache
   docker compose up -d
   ```
3. **Commit:** Version control all changes
4. **Share:** Push to Git repository

---

## 📝 License

See [LICENSE](LICENSE) file for details.

---

## 🆘 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Docker logs: `docker compose logs`
3. Verify setup with deployment script
4. Check Docker Desktop status and resources

---

**Last Updated:** November 2025  
**Tested On:** Windows 11 Pro (22H2), Docker Desktop 4.25.0, VS Code 1.84.0


## Deploy the container using Docker Desktop

We build the image which we call **```rust-ubuntu-dev```** by running from within ```C:\\rustdev\container\```: 
```bash
    docker build -t rust-ubuntu-dev:0.1.0 .
```

We then launch the container, exposing the port 2222 for SSH connexion:
```bash
    docker run -d \
      -p 2222:22 \
      -v C:/rustdev/projects:/workspace \
      --name rust-dev-container \
      rust-ubuntu-dev
```
or
```bash
    docker run -d -p 2222:22 -v C:/rustdev/projects:/workspace --name rust-dev-container rust-ubuntu-dev
```

The code will be persisted in ```C:\rust-dev\projects\```, which is mapped into ```/workspace``` (which belongs to 'rustdev' user).

## VS code configuration

NB: you won't need Git installed in Win11 on the laptop, since you'll use the native git installed in the Ubuntu container.

### Step 1: install the 'remote SSH' and 'rust-analyzer' extensions
Go to the Extensions view (`Ctrl+Shift+X` or click the Extensions icon in the left sidebar) and search for and install the following extensions:
- **Remote - SSH** by Microsoft: This enables connecting to remote hosts (like your container) via SSH. It may prompt you to install the "Remote Development" pack if not already present.
- **rust-analyzer** by rust-lang: This provides Rust-specific features like syntax highlighting, autocompletion, linting, debugging, and code navigation. Install it on the host first; you'll install it on the remote side later for optimal performance.
- Restart VS Code if prompted to apply the changes.

### Step 2: Configure SSH Connection Settings
1. Open the SSH configuration file in VS Code:
   - Press `Ctrl+Shift+P` to open the Command Palette.
   - Type "Remote-SSH: Open Configuration File" and select it.
   - Choose the default SSH config file (usually `C:\Users\YourUsername\.ssh\config` on Windows; replace `YourUsername` with your actual Windows username). If the file doesn't exist, VS Code will create it.
2. Add the following configuration block to the file (append it if the file already has content):
   ```
   Host rust-container
       HostName localhost
       Port 2222
       User rustdev
   ```
   - **Explanation**:
     - `Host rust-container`: A friendly name for this connection profile.
     - `HostName localhost`: Connects to the container via your local machine (since the port is mapped locally).
     - `Port 2222`: The port mapped on your host (matching the `-p 2222:22` in your `docker run` command).
     - `User rustdev`: The non-root user in the container.
3. Save the file (Ctrl+S). This creates a reusable SSH profile.

**Optional: Set up passwordless SSH for convenience** (recommended to avoid entering the password `Hp77M&zzu$JoG1` every time):
1. On your Windows host, generate an SSH key pair if you don't have one:
   - Open PowerShell or CMD.
   - Run (having replaced with your own email):
       ```bash
         ssh-keygen -t ed25519 -C "your_email@example.com"  
       ``` 
   - Press Enter to accept the default location (`C:\Users\YourUsername\.ssh\id_ed25519`).
   - Enter a passphrase if desired (or leave blank for no passphrase).
2. Copy the public key to the container (transiting via the volume):
   - copy the `id_ed25519.pub` file to the `C:\rustdev\projects`directory and rename the file as `authorized_keys` (with no extension)
   - Ensure the container is running (`docker ps` to check; start with `docker start rust-dev-container` if needed).
   - Run from the Windows shell:
     ```bash
         docker exec -it rust-dev-container mkdir -p /home/rustdev/.ssh
         docker exec -it rust-dev-container mv /workspace/authorized_keys /home/rustdev/.ssh'
         docker exec -it rust-dev-container chown -R rustdev:rustdevteam /home/rustdev/.ssh
         docker exec -it rust-dev-container chmod 700 /home/rustdev/.ssh
         docker exec -it rust-dev-container chmod 600 /home/rustdev/.ssh/authorized_keys
     ```
4. Test passwordless connection: Run `ssh rust-container` in PowerShell (you should connect without a password prompt).

#### Step 3: Connect VS Code to the Container
1. In VS Code, open the Command Palette (`Ctrl+Shift+P`).
2. Type "Remote-SSH: Connect to Host" and select it.
3. Choose "rust-container" from the list of hosts.
4. Enter the password `Hp77M&zzu$JoG1` if prompted (or skip if using passwordless SSH).
   - VS Code will establish the connection. You'll see a green status indicator in the bottom-left corner: "SSH: rust-container".
   - If there's an error (e.g., connection refused), ensure the container is running (`docker ps`) and the port mapping is correct.

#### Step 4: Open the Workspace and Install Remote Extensions
1. Once connected, VS Code prompts you to open a folder on the remote machine.
   - Select `/workspace` (this is the mounted directory where your code is persisted and synchronized with `C:\rustdev\projects` on your host).
2. Install Rust extensions on the remote side for better performance:
   - Go to the Extensions view (`Ctrl+Shift+X`).
   - Search for "rust-analyzer".
   - Click "Install in SSH: rust-container" (this installs it in the container's environment).
3. (Optional) Install other useful extensions on the remote:
   - "Cargo" by panicbit: For Cargo command integration.
   - "Dependi" by Fill Labs (dependi.io): For managing Rust dependencies.
   - "Even Better TOML" by tamasfe: For editing Cargo.toml files.
   - Install them via "Install in SSH: rust-container".

#### Step 5: Test the Rust Toolchain in VS Code
1. Open a terminal in VS Code:
   - Press `Ctrl+`` (backtick) or go to Terminal > New Terminal.
   - The terminal should open in the remote container (prompt shows `rustdev@container-id:/workspace$` or similar).
2. Verify the Rust toolchain:
   ```
   rustc --version  # Should output: rustc 1.90.0 (or your installed version)
   cargo --version  # Should output: cargo 1.90.0 (or your installed version)
   rustup toolchain list  # Should show: stable-x86_64-unknown-linux-gnu (default)
   ```
3. Create a test Rust project:
   ```
   cargo new test_project
   cd test_project
   cargo build  # Builds the project
   cargo run    # Runs it (should print "Hello, world!")
   ```
   - If this works, the toolchain is accessible.

#### Step 6: Efficiently Use the Rust Toolchain in VS Code
1. **Edit and Navigate Code**:
   - Open `src/main.rs` in VS Code (from `/workspace/test_project`).
   - rust-analyzer should provide:
     - Autocompletion: Type `println!(` and press Ctrl+Space for suggestions.
     - Linting: Errors/warnings appear inline (e.g., red squiggles).
     - Go to Definition: Right-click a symbol and select "Go to Definition".
     - Hover for docs: Hover over `println!` for documentation.

2. **Debugging**:
   - Create a debug configuration:
     - Go to Run > Add Configuration (or open `.vscode/launch.json` in the project folder).
     - Select "Rust" or add manually:
       ```json
       {
           "version": "0.2.0",
           "configurations": [
               {
                   "type": "lldb",
                   "request": "launch",
                   "name": "Debug executable 'test_project'",
                   "cargo": {
                       "args": ["build", "--bin=test_project", "--package=test_project"]
                   },
                   "args": [],
                   "cwd": "${workspaceFolder}"
               }
           ]
       }
       ```
   - Set breakpoints: Click in the gutter next to line numbers in `main.rs`.
   - Start debugging: Press F5 or go to Run > Start Debugging.
   - Step through code using F10 (step over), F11 (step into), etc.

3. **Cargo Commands Integration**:
   - Use the Command Palette (`Ctrl+Shift+P`):
     - Type "Cargo" to see commands like "Cargo: Build", "Cargo: Run", "Cargo: Test".
   - Or use the integrated terminal for custom commands (e.g., `cargo check`, `cargo clippy` for linting).

4. **Version Control with Git**:
   - Since Git is installed in the container, initialize a repo:
     ```
     git init
     git add .
     git commit -m "Initial commit"
     ```
   - Use VS Code's Source Control view (left sidebar) for commits, pushes, etc. (connect to a remote repo like GitHub if needed).

5. **Efficient Workflow Tips**:
   - **Code Synchronization**: Changes in `/workspace` automatically sync to `C:\rustdev\projects` on your host (due to the volume mount). Edit files in VS Code, and they're persisted even if the container stops.
   - **Reconnect Quickly**: If disconnected, use Command Palette > "Remote-SSH: Connect to Host" > "rust-container".
   - **Performance**: Run resource-intensive tasks (e.g., `cargo build --release`) in the terminal; the container isolates them from your host.
   - **Updates**: To update Rust, run `rustup update` in the remote terminal.
   - **Troubleshooting**: If rust-analyzer doesn't activate, reload VS Code (Command Palette > "Reload Window"). Check VS Code's Output panel (View > Output > Rust Analyzer) for errors.
   - **Stop/Start Container**: If the container stops, restart with `docker start rust-dev-container` on your host, then reconnect in VS Code.

This setup provides an efficient, isolated Rust development environment in Linux while using VS Code on Windows. If you encounter errors (e.g., connection issues), check Docker logs (`docker logs rust-dev-container`) or provide details for further help.
