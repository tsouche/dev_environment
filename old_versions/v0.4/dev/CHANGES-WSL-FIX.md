# Changes for WSL Mount Issue Fix - v0.4 Dev Environment

## Summary

Fixed the WSL mount issue that made the `set_backend` directory unusable when mounted directly from Windows to the Linux container. The solution changes the mount strategy to mount only the parent directory and clone the Git repository from within the container.

---

## Files Modified

### 1. `.env`
**Changed:**
- `PROJECT_PATH` from `C:/rustdev/projects/set_backend` to `C:/rustdev/projects`
- Added `GIT_REPO=https://github.com/tsouche/set_backend.git`

**Why:**
- Mount parent directory only to avoid WSL filesystem translation issues
- Store repository URL for reference

---

### 2. `docker-compose-dev.yml`
**Changed:**
- Volume mount from `${PROJECT_PATH}:/workspace/${PROJECT_DIR}` to `${PROJECT_PATH}:/workspace`

**Why:**
- Mount parent directory instead of project directory directly
- Allows cloning repository inside container without WSL mount issues

---

### 3. `deploy-dev.ps1` (PowerShell deployment script)
**Changed:**
- Removed creation of sample Rust project (Cargo.toml and main.rs)
- Modified directory creation to only create parent directory
- Updated deployment success message with new workflow instructions
- Added warnings about cloning from within the container

**Why:**
- Don't pre-create project files that will be cloned from Git
- Provide clear instructions for the new workflow

---

### 4. `deploy-dev.sh` (Bash deployment script)
**Changed:**
- Same changes as PowerShell script (removed sample project creation)
- Modified directory creation to only create parent directory
- Updated deployment success message with new workflow instructions
- Added warnings about cloning from within the container

**Why:**
- Keep Bash and PowerShell scripts in sync
- Support both Windows PowerShell and Git Bash/WSL users

---

## New Workflow

### Old Workflow (Problematic)
1. Run `deploy-dev.ps1`
2. Script creates sample project at `C:/rustdev/projects/set_backend`
3. This gets mounted to `/workspace/set_backend` via WSL
4. **Problem:** WSL mount makes files unusable in Linux container

### New Workflow (Fixed)
1. Run `deploy-dev.ps1`
2. Script creates only `C:/rustdev/projects` directory
3. This gets mounted to `/workspace` via WSL
4. Connect to container via VS Code Remote-SSH
5. Open `/workspace` folder in VS Code
6. Clone repository **inside the container**: `git clone https://github.com/tsouche/set_backend.git`
7. Open `/workspace/set_backend` folder
8. Start development with `cargo build`

---

## Technical Details

### Why the Old Approach Failed

When mounting `C:/rustdev/projects/set_backend` directly:
```
Windows FS (NTFS) → WSL Translation Layer → Linux Container
                     ↑
                   Problem: File permissions, inodes, and file system
                   operations don't translate correctly
```

### Why the New Approach Works

When cloning inside the container:
```
Windows FS (NTFS) → WSL Translation Layer → /workspace (parent only)
                                            ↓
                                         git clone creates native
                                         Linux files in container
```

The Git clone happens inside the Linux container, creating files with proper:
- Linux file permissions
- Correct ownership (rustdev:rustdevteam)
- Native Linux inodes and metadata
- No Windows-to-Linux translation issues

---

## User-Facing Changes

### Deployment Script Output
**Old message:**
```
Next Steps:
  1. In VS Code, press Ctrl+Shift+P
  2. Type 'Remote-SSH: Connect to Host'
  3. Select 'rust-dev'
  4. Open folder: /workspace/set_backend
  5. Run: cargo build
```

**New message:**
```
Next Steps:
  1. In VS Code, press Ctrl+Shift+P
  2. Type 'Remote-SSH: Connect to Host'
  3. Select 'rust-dev'
  4. Open folder: /workspace
  5. Clone repository: https://github.com/tsouche/set_backend.git
     git clone https://github.com/tsouche/set_backend.git
  6. Open the cloned project: /workspace/set_backend
  7. Run: cargo build

IMPORTANT:
  Clone the repository FROM WITHIN the container (via VS Code terminal)
  DO NOT clone on Windows and mount it - this causes WSL mount issues!
```

---

## Benefits

✅ **Solves WSL mount issues** - No more file system errors  
✅ **Normal Git workflow** - All git commands work as expected  
✅ **Fast file operations** - Native Linux files, no translation layer  
✅ **Preserved caches** - Cargo and build caches still mounted separately  
✅ **Cleaner separation** - Windows only sees parent directory  
✅ **More flexible** - Can clone multiple projects in /workspace  

---

## Rollback (If Needed)

If you need to revert to the old approach:

1. **Restore `.env`:**
   ```bash
   PROJECT_PATH=C:/rustdev/projects/set_backend
   # Remove GIT_REPO line
   ```

2. **Restore `docker-compose-dev.yml`:**
   ```yaml
   volumes:
     - ${PROJECT_PATH}:/workspace/${PROJECT_DIR}
   ```

3. **Restore deployment scripts** (git revert or restore from backup)

4. **Redeploy:**
   ```powershell
   docker compose -f docker-compose-dev.yml down -v
   .\deploy-dev.ps1
   ```

---

## Testing Checklist

- [x] Modified `.env` with new PROJECT_PATH
- [x] Modified `docker-compose-dev.yml` with new volume mount
- [x] Updated `deploy-dev.ps1` with new workflow
- [x] Updated `deploy-dev.sh` with new workflow
- [x] Created `WORKFLOW.md` documentation
- [ ] Test deployment on Windows laptop
- [ ] Test VS Code Remote-SSH connection
- [ ] Test git clone inside container
- [ ] Test cargo build
- [ ] Verify file permissions are correct
- [ ] Verify git operations work normally

---

## Additional Documentation

See `WORKFLOW.md` for detailed step-by-step instructions for the new workflow.

---

**Date:** November 9, 2025  
**Issue:** WSL mount makes set_backend directory unusable in Linux container  
**Solution:** Mount parent directory only, clone repository inside container  
**Status:** Ready for testing
