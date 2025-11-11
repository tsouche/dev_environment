# Development Workflow - v0.4 (Updated for WSL Compatibility)

## Problem Addressed

When mounting `C:/rustdev/projects/set_backend` directly to the Linux container, WSL creates a mount that makes the directory unusable from within the container. This causes file system errors and prevents proper development.

## Solution

Mount the **parent directory** (`C:/rustdev/projects`) to `/workspace` in the container, then clone the Git repository **from within the container** after connecting via VS Code Remote-SSH.

---

## Setup Steps

### 1. Deploy the Development Environment

```powershell
cd v0.4\dev
.\deploy-dev.ps1
```

or

```bash
cd v0.4/dev
./deploy-dev.sh
```

This will:
- Create `C:/rustdev/projects` directory on Windows
- Build and start the dev container
- Configure SSH access for VS Code
- Start MongoDB and Mongo Express

**Note:** The `set_backend` project directory will **NOT** be created yet.

---

### 2. Connect to Container via VS Code

1. Open VS Code
2. Press `Ctrl+Shift+P`
3. Type: **Remote-SSH: Connect to Host**
4. Select: **rust-dev**
5. Wait for VS Code to connect to the container

---

### 3. Open Workspace Folder

1. In the connected VS Code window, click **File → Open Folder**
2. Navigate to: `/workspace`
3. Click **OK**

You should now see the `/workspace` directory (which is empty or has only cache folders).

---

### 4. Clone the Repository

**IMPORTANT:** Clone from **within the VS Code terminal** connected to the container.

1. Open a terminal in VS Code (`Ctrl+``)
2. Verify you're in the container:
   ```bash
   pwd  # Should show /workspace
   whoami  # Should show rustdev
   ```
3. Clone the repository:
   ```bash
   git clone https://github.com/tsouche/set_backend.git
   ```
4. Navigate into the project:
   ```bash
   cd set_backend
   ```

---

### 5. Start Development

1. In VS Code, click **File → Open Folder**
2. Navigate to: `/workspace/set_backend`
3. Click **OK**
4. Build the project:
   ```bash
   cargo build
   ```
5. Run the project:
   ```bash
   cargo run
   ```

---

## Why This Works

### ❌ Old Approach (Problematic)
```
Windows: C:/rustdev/projects/set_backend
         ↓ (WSL mount - causes issues)
Container: /workspace/set_backend
```

**Problem:** WSL mount creates incompatible file system layer

### ✅ New Approach (Works)
```
Windows: C:/rustdev/projects/
         ↓ (WSL mount - parent only)
Container: /workspace/
           ↓ (native Linux git clone)
           /workspace/set_backend
```

**Solution:** Clone happens inside the Linux container, avoiding WSL mount issues

---

## Configuration Changes

### `.env` File
```bash
# Old
PROJECT_PATH=C:/rustdev/projects/set_backend

# New
PROJECT_PATH=C:/rustdev/projects
GIT_REPO=https://github.com/tsouche/set_backend.git
```

### `docker-compose-dev.yml`
```yaml
# Old
volumes:
  - ${PROJECT_PATH}:/workspace/${PROJECT_DIR}

# New
volumes:
  - ${PROJECT_PATH}:/workspace
```

---

## Directory Structure

### On Windows Host
```
C:/rustdev/
└── projects/              ← Mounted to container
    └── (empty initially)
```

### Inside Container (after cloning)
```
/workspace/
├── set_backend/           ← Cloned from git inside container
│   ├── src/
│   ├── Cargo.toml
│   └── ...
└── target/                ← Build cache (from separate volume)
```

---

## Important Notes

1. **Never clone on Windows and mount it** - This causes the WSL mount issue
2. **Always clone inside the container** - Use the VS Code terminal after connecting
3. **Use Git from inside the container** - All git operations work normally
4. **Cargo cache is preserved** - `~/.cargo/registry` is mounted separately
5. **Target cache is preserved** - `/workspace/target` is mounted separately

---

## Troubleshooting

### "Permission denied" errors
- Make sure you cloned the repo inside the container (not on Windows)
- Check file ownership: `ls -la /workspace/set_backend`
- Files should be owned by `rustdev:rustdevteam`

### "No such file or directory" errors
- Verify you're in the correct directory: `pwd`
- Verify the repo was cloned: `ls /workspace/`
- You should see `set_backend` directory

### Git authentication issues
- Use HTTPS URL for public repos
- For private repos, set up SSH keys inside the container:
  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com"
  cat ~/.ssh/id_ed25519.pub
  # Add this to your GitHub account
  ```

### Need to start fresh
```bash
# On Windows
cd v0.4/dev
docker compose -f docker-compose-dev.yml down -v

# Delete mounted directory
rm -rf C:/rustdev/projects/set_backend

# Redeploy
.\deploy-dev.ps1

# Reconnect via VS Code and clone again
```

---

## Benefits of This Approach

✅ **No WSL mount issues** - Git clone creates native Linux files  
✅ **Fast file operations** - No translation layer between Windows and Linux  
✅ **Normal Git workflow** - All git commands work as expected  
✅ **Preserved caches** - Cargo and build caches still work via separate volumes  
✅ **Clean separation** - Windows only sees the parent directory  

---

## Reference

- **Windows mount path:** `C:/rustdev/projects`
- **Container workspace:** `/workspace`
- **Git repository:** `https://github.com/tsouche/set_backend.git`
- **SSH host alias:** `rust-dev`
- **SSH port:** `2222`
- **Container user:** `rustdev`
