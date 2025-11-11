# Proposal: Make v0.2 Generic

**Date:** November 8, 2025  
**Objective:** Remove project-specific references and make the environment generic for any Rust project

---

## 🎯 Executive Summary

The current v0.2 environment contains **60+ references** to the specific project "SET game backend". This proposal outlines changes to make the environment generic and reusable for any Rust + MongoDB project.

---

## 📊 Current Project-Specific References

### Category 1: Directory/Project Names
- **`set_backend`** - 30+ occurrences (directory name, paths, project name)
- **Container names:** `set-rust-dev`, `set-mongodb`, `set-mongo-express`

### Category 2: Database Names
- **`set_game_db`** - Database name (20+ occurrences)
- **`set_app_user`** - MongoDB user (10+ occurrences)
- **`set_app_password`** - MongoDB password (10+ occurrences)

### Category 3: Collection Names
- **`games`**, **`players`**, **`scores`** - Project-specific collections

---

## 🔄 Proposed Changes

### 1. Generic Naming Convention

| Current (Specific) | Proposed (Generic) | Rationale |
|-------------------|-------------------|-----------|
| `set_backend` | `rust_project` | Generic Rust project name |
| `set-rust-dev` | `rust-dev-container` | Descriptive container name |
| `set-mongodb` | `rust-mongodb` | Consistent with dev container |
| `set-mongo-express` | `rust-mongo-express` | Consistent naming |
| `set_game_db` | `rust_app_db` | Generic application database |
| `set_app_user` | `app_user` | Simple, generic user |
| `set_app_password` | `app_password` | Simple, generic password |
| Collections: `games`, `players`, `scores` | `items`, `users` (examples) | Generic examples |

### 2. Path Structure

**Current:**
```
v0.2/
├── set_backend/
│   ├── Cargo.toml (name = "set_backend")
│   └── src/main.rs
```

**Proposed:**
```
v0.2/
├── rust_project/
│   ├── Cargo.toml (name = "rust_project")
│   └── src/main.rs
```

**Or even more flexible:**
```
v0.2/
├── projects/              # User can create multiple projects
│   ├── my_api/
│   ├── my_backend/
│   └── my_service/
```

---

## 📝 Files Requiring Changes

### 1. docker-compose-v02.yml

**Changes:**
```yaml
# Container names
container_name: set-rust-dev → rust-dev-container
container_name: set-mongodb → rust-mongodb
container_name: set-mongo-express → rust-mongo-express

# Environment variables
MONGODB_URI: ...set_game_db → ...rust_app_db
MONGODB_DATABASE: set_game_db → rust_app_db
MONGODB_USER: set_app_user → app_user
MONGODB_PASSWORD: set_app_password → app_password
MONGO_INITDB_DATABASE: set_game_db → rust_app_db

# Volume mounts
- ./set_backend:/workspace/set_backend → ./rust_project:/workspace/rust_project
```

**Line Count:** ~15 lines

### 2. deploy-v02.sh

**Changes:**
```bash
# Directory creation
mkdir -p "$SCRIPT_DIR/set_backend/src" → "$SCRIPT_DIR/rust_project/src"

# Cargo.toml
name = "set_backend" → name = "rust_project"

# MongoDB init script
db.getSiblingDB('set_game_db') → db.getSiblingDB('rust_app_db')
user: 'set_app_user' → user: 'app_user'
pwd: 'set_app_password' → pwd: 'app_password'
db: 'set_game_db' → db: 'rust_app_db'

# Collections (make them examples)
db.createCollection('games') → db.createCollection('items')  # Example
db.createCollection('players') → db.createCollection('users')  # Example
db.createCollection('scores') → db.createCollection('data')   # Example

# Instructions
"Open /workspace/set_backend" → "Open /workspace/rust_project"
```

**Line Count:** ~20 lines

### 3. deploy-v02.ps1

**Same changes as deploy-v02.sh**

**Line Count:** ~20 lines

### 4. documentation-v02.md

**Changes:**
```markdown
# Architecture diagram
(./set_backend) → (./rust_project)

# Directory structure
├── set_backend/ → ├── rust_project/

# Path mapping table
.\v0.2\set_backend\ → .\v0.2\rust_project\
/workspace/set_backend/ → /workspace/rust_project/

# File descriptions
./set_backend:/workspace/set_backend → ./rust_project:/workspace/rust_project

# Instructions
New-Item -ItemType Directory -Force set_backend\src → rust_project\src
set_backend/Cargo.toml → rust_project/Cargo.toml
name = "set_backend" → name = "rust_project"

# MongoDB references
set_game_db → rust_app_db
set_app_user → app_user
set_app_password → app_password

# Collection names in examples
games, players, scores → items, users, data (as examples)

# Command examples
/workspace/set_backend → /workspace/rust_project
rustdev@<container-id>:/workspace/set_backend$ → rustdev@<container-id>:/workspace/rust_project$

# Docker commands
docker cp set-mongodb → docker cp rust-mongodb
```

**Line Count:** ~50 lines

### 5. VERSION.md

**Changes:**
```markdown
# Database section
- **Database:** set_game_db → rust_app_db

# File structure
├── set_backend/ → ├── rust_project/
```

**Line Count:** ~3 lines

### 6. MIGRATION.md

**Changes:**
```markdown
# Path references
- Workspace folder path: `/workspace/set_backend` → `/workspace/rust_project`
```

**Line Count:** ~2 lines

---

## 🎨 Recommended Approach: Configuration-Based

### Option A: Environment Variables (Recommended)

Create a `.env` file for easy customization:

**`.env`:**
```bash
# Project Configuration
PROJECT_NAME=rust_project
PROJECT_DIR=rust_project

# Database Configuration  
DB_NAME=rust_app_db
DB_USER=app_user
DB_PASSWORD=app_password

# Container Names
CONTAINER_RUST_DEV=rust-dev-container
CONTAINER_MONGODB=rust-mongodb
CONTAINER_MONGO_EXPRESS=rust-mongo-express
```

**Benefits:**
- Users can customize without editing multiple files
- Single source of truth
- Easy to version control user-specific settings (.env.local)

**Usage in docker-compose-v02.yml:**
```yaml
services:
  rust-dev:
    container_name: ${CONTAINER_RUST_DEV:-rust-dev-container}
    volumes:
      - ./${PROJECT_DIR:-rust_project}:/workspace/${PROJECT_DIR:-rust_project}
    environment:
      - MONGODB_DATABASE=${DB_NAME:-rust_app_db}
      - MONGODB_USER=${DB_USER:-app_user}
      - MONGODB_PASSWORD=${DB_PASSWORD:-app_password}
```

### Option B: Simple Generic Names (Simpler)

Just replace with generic names throughout. Less flexible but simpler for users.

---

## 📋 Implementation Plan

### Phase 1: Core Files (Essential)
1. ✅ Update `docker-compose-v02.yml`
2. ✅ Update `deploy-v02.sh`
3. ✅ Update `deploy-v02.ps1`

**Impact:** Environment will work with generic names

### Phase 2: Documentation (Important)
4. ✅ Update `documentation-v02.md`
5. ✅ Update `VERSION.md`
6. ✅ Update `MIGRATION.md`

**Impact:** Users have accurate documentation

### Phase 3: Configuration (Optional Enhancement)
7. ⭐ Create `.env.example` file
8. ⭐ Add `.env` support to docker-compose
9. ⭐ Update scripts to read from `.env`
10. ⭐ Add configuration section to documentation

**Impact:** Users can easily customize

---

## 🔍 Testing Checklist

After changes:
- [ ] Deploy script creates `rust_project/` directory
- [ ] Docker compose builds successfully
- [ ] Containers start with new names
- [ ] MongoDB initializes with `rust_app_db`
- [ ] Volume mounts work correctly
- [ ] SSH connection works
- [ ] Sample Rust app connects to MongoDB
- [ ] Documentation examples are accurate

---

## 💡 Additional Recommendations

### 1. Add Project Template Support

Allow users to choose project type during deployment:

```bash
# In deploy script
echo "Select project type:"
echo "  1) Simple Rust application"
echo "  2) Rust + MongoDB backend"
echo "  3) Rust web API (Actix)"
echo "  4) Custom (manual setup)"
```

### 2. Make MongoDB Optional

Some users may not need MongoDB:

```yaml
# docker-compose-v02.yml
profiles:
  - database  # Add profile to MongoDB services
```

Usage:
```bash
# With database
docker compose --profile database up -d

# Without database
docker compose up -d
```

### 3. Add Project Generator

```bash
# In deploy script
create_project() {
    local project_name=$1
    cargo new "$SCRIPT_DIR/$project_name"
    # Add dependencies based on user selection
}
```

---

## 📊 Impact Analysis

### Benefits
✅ **Reusability:** Environment can be used for any Rust project  
✅ **Clarity:** No confusion from project-specific names  
✅ **Professional:** More suitable for distribution  
✅ **Flexibility:** Easy to customize for different projects  
✅ **Documentation:** Examples are clearer as generic patterns  

### Risks
⚠️ **Breaking Change:** Existing users need to update  
⚠️ **Migration Needed:** If v0.2 already deployed, users must migrate  

### Mitigation
- Keep v0.2 as-is, create v0.3 with generic names
- Provide migration guide for existing users
- Maintain backward compatibility with environment variables

---

## 🎯 Recommendation

### Recommended Approach:

**Create v0.3 with generic implementation:**

1. Copy v0.2 → v0.3
2. Implement all generic changes in v0.3
3. Add `.env` support for customization
4. Keep v0.2 available for existing SET project users
5. Document migration path from v0.2 to v0.3

**Benefits:**
- Non-breaking change
- Users can choose based on needs
- Clean separation of concerns
- Follows semantic versioning

### Alternative: Update v0.2 In-Place

If no active users exist:
1. Update all v0.2 files with generic names
2. Mark as "v0.2.1" or "v0.2-generic"
3. Add note about breaking change
4. Provide migration guide

---

## 📝 Example Configuration File

**`.env.example`:**
```bash
################################################################################
# Rust Development Environment Configuration
# 
# Copy this file to .env and customize for your project
################################################################################

# ==============================================================================
# Project Settings
# ==============================================================================
# Project name (alphanumeric and underscores only)
PROJECT_NAME=rust_project

# Project directory name (will be created if doesn't exist)
PROJECT_DIR=rust_project

# ==============================================================================
# Container Configuration
# ==============================================================================
# Container names (must be unique on your system)
CONTAINER_RUST_DEV=rust-dev-container
CONTAINER_MONGODB=rust-mongodb
CONTAINER_MONGO_EXPRESS=rust-mongo-express

# ==============================================================================
# Port Mappings
# ==============================================================================
# SSH port (host:container)
SSH_PORT=2222

# Application port
APP_PORT=8080

# MongoDB port
MONGO_PORT=27017

# Mongo Express port
MONGO_EXPRESS_PORT=8081

# ==============================================================================
# Database Configuration
# ==============================================================================
# MongoDB database name
DB_NAME=rust_app_db

# Application user credentials
DB_USER=app_user
DB_PASSWORD=app_password

# Admin credentials (for MongoDB root user)
DB_ADMIN_USER=admin
DB_ADMIN_PASSWORD=admin123

# ==============================================================================
# Development Settings
# ==============================================================================
# Rust log level (error, warn, info, debug, trace)
RUST_LOG=debug

# User/Group IDs (for NAS compatibility)
USER_UID=1026
USER_GID=110
```

---

## 🚀 Quick Win: Minimal Changes

If full implementation is too much, here's a minimal viable change:

### Just rename these 3 items:
1. `set_backend` → `rust_project`
2. `set_game_db` → `rust_app_db`
3. Container names → add `rust-` prefix

**Impact:** ~110 lines across 6 files  
**Time:** ~30 minutes  
**Result:** 90% more generic

---

## ✅ Decision Needed

Please choose:

**Option 1:** Update v0.2 in-place (breaking change)  
**Option 2:** Create v0.3 with generic names (recommended)  
**Option 3:** Add .env support to v0.2 (most flexible)  
**Option 4:** Minimal changes only (quickest)

---

**Prepared by:** GitHub Copilot  
**Date:** November 8, 2025  
**Status:** Awaiting approval
