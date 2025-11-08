# Migration Guide: v0.2 → v0.3

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Estimated Time:** 15-30 minutes

---

## 📋 Overview

This guide helps you migrate from version 0.2 to version 0.3 of the Rust development environment. Version 0.3 introduces comprehensive `.env` configuration support and generic naming conventions.

### Why Migrate?

**v0.3 Benefits:**
- ✅ **Flexibility**: Configure all settings via `.env` file
- ✅ **Multi-Project**: Run multiple environments simultaneously
- ✅ **Generic**: Not tied to specific project domain
- ✅ **Maintainability**: Centralized configuration management
- ✅ **Team-Friendly**: Share template, customize locally

**v0.2 Limitations:**
- ❌ Hardcoded project-specific names (`set_backend`, `set_game_db`)
- ❌ Manual file editing required for customization
- ❌ Difficult to run multiple instances
- ❌ Port conflicts when scaling

---

## 🎯 Migration Strategy Options

Choose the approach that best fits your needs:

### Option 1: Fresh Start (Recommended)

**Best For:** New projects, starting clean, learning v0.3

**Pros:**
- Clean generic naming
- Latest best practices
- Full feature utilization

**Cons:**
- Need to copy existing code
- Update hardcoded references

**Time:** 15 minutes

### Option 2: Preserve v0.2 Names

**Best For:** Existing projects, minimal code changes, quick migration

**Pros:**
- Keep existing names
- No code changes needed
- Drop-in replacement

**Cons:**
- Miss generic naming benefits
- Still tied to v0.2 conventions

**Time:** 10 minutes

### Option 3: Hybrid Approach

**Best For:** Gradual migration, mixed requirements

**Pros:**
- Flexible customization
- Keep some v0.2 names
- Adopt v0.3 features gradually

**Cons:**
- Requires thoughtful planning
- Mixed naming conventions

**Time:** 20-30 minutes

---

## 🚀 Migration Steps

### Pre-Migration Checklist

Before starting, ensure:

- [ ] Current v0.2 environment is backed up
- [ ] Existing data is backed up (MongoDB)
- [ ] No uncommitted code changes
- [ ] Docker containers are stopped
- [ ] You have the v0.3 files

**Backup Commands:**

```bash
# Stop v0.2 environment
cd v0.2
docker compose down

# Backup MongoDB data
docker run --rm -v dev_environment_v0.2_mongodb-data:/data \
  -v $(pwd)/backup:/backup ubuntu \
  tar czf /backup/mongodb-backup.tar.gz /data

# Backup your source code
tar czf ../set_backend_backup.tar.gz set_backend/
```

---

## 📦 Option 1: Fresh Start (Recommended)

### Step 1: Prepare v0.3 Environment

```bash
# Navigate to v0.3 directory
cd /path/to/dev_environment/v0.3

# Copy environment template
cp .env.example .env

# (Optional) Review and customize .env
nano .env  # or your preferred editor
```

**Recommended .env Customizations:**

```bash
# Customize these for your project
PROJECT_NAME=my_project           # Your project name
PROJECT_DIR=my_project_backend    # Directory name
DB_NAME=my_project_db            # Database name
DB_USER=my_user                  # Database user

# Ports (change if v0.2 still running or conflicts)
SSH_PORT=2222                    # VS Code SSH
APP_PORT=8080                    # Your application
MONGO_PORT=27017                 # MongoDB
MONGO_EXPRESS_PORT=8081          # Mongo Express UI
```

### Step 2: Copy Existing Code

```bash
# Copy your Rust project from v0.2
cp -r ../v0.2/set_backend/* ./rust_project/

# Or if you customized PROJECT_DIR in .env:
# cp -r ../v0.2/set_backend/* ./$PROJECT_DIR/
```

### Step 3: Update Code References

**Update MongoDB Connection Strings:**

**Before (v0.2 - hardcoded):**
```rust
// src/main.rs or database.rs
let uri = "mongodb://mongo-db:27017/set_game_db";
let client = Client::with_uri_str(uri).await?;
```

**After (v0.3 - configurable):**
```rust
// src/main.rs or database.rs
use std::env;

let db_name = env::var("DB_NAME").unwrap_or_else(|_| "rust_app_db".to_string());
let uri = format!("mongodb://mongo-db:27017/{}", db_name);
let client = Client::with_uri_str(&uri).await?;
```

**Update Collection Names:**

**Before (v0.2):**
```rust
let games = db.collection::<Game>("games");
let players = db.collection::<Player>("players");
let scores = db.collection::<Score>("scores");
```

**After (v0.3):**
```rust
let coll1 = env::var("COLLECTION_1").unwrap_or_else(|_| "items".to_string());
let coll2 = env::var("COLLECTION_2").unwrap_or_else(|_| "users".to_string());
let coll3 = env::var("COLLECTION_3").unwrap_or_else(|_| "data".to_string());

let items = db.collection::<Item>(&coll1);
let users = db.collection::<User>(&coll2);
let data = db.collection::<Data>(&coll3);
```

**Or keep v0.2 names in .env:**
```bash
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores
```

### Step 4: Deploy v0.3

```bash
# Generate SSH keys (if not reusing v0.2 keys)
ssh-keygen -t ed25519 -f rust_dev_key -N ""

# Deploy
./deploy-v03.sh  # Linux/Mac
# or
.\deploy-v03.ps1  # Windows PowerShell

# Wait for services to start
```

### Step 5: Update VS Code SSH Configuration

**Edit SSH Config:**

**Linux/Mac:** `~/.ssh/config`  
**Windows:** `C:\Users\YourUsername\.ssh\config`

**Update or Add:**
```
Host rust-dev-v03
    HostName localhost
    Port 2222                                    # Or your SSH_PORT from .env
    User rustdev                                 # Or your USERNAME from .env
    IdentityFile /path/to/v0.3/rust_dev_key      # Update path!
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### Step 6: Connect and Test

1. **Open VS Code**
2. **Connect via Remote-SSH** to `rust-dev-v03`
3. **Open folder:** `/workspace/rust_project` (or your PROJECT_DIR)
4. **Test build:**
   ```bash
   cargo build
   cargo run
   ```
5. **Test database connection**

### Step 7: Migrate Data (If Needed)

If you have existing data in v0.2 MongoDB:

```bash
# Export from v0.2
docker compose -f ../v0.2/docker-compose-v02.yml exec mongo-db \
  mongodump --db set_game_db --out /tmp/dump

# Copy dump to host
docker compose -f ../v0.2/docker-compose-v02.yml cp \
  mongo-db:/tmp/dump ./dump

# Import to v0.3
docker compose exec mongo-db \
  mongorestore --db rust_app_db /tmp/dump/set_game_db

# Copy dump to v0.3 container first:
docker compose cp ./dump mongo-db:/tmp/dump
```

### Step 8: Cleanup v0.2 (Optional)

Once v0.3 is working:

```bash
cd ../v0.2
docker compose down -v  # Removes containers and volumes
# Keep backup files for safety
```

---

## 🔄 Option 2: Preserve v0.2 Names

This option keeps all v0.2 naming conventions in v0.3.

### Step 1: Configure .env with v0.2 Names

```bash
cd v0.3
cp .env.example .env
```

**Edit .env to match v0.2:**

```bash
# Project Configuration (v0.2 names)
PROJECT_NAME=set_backend
PROJECT_DIR=set_backend
USERNAME=rustdev

# Container Names (v0.2 style)
CONTAINER_RUST_DEV=set-rust-dev
CONTAINER_MONGODB=set-mongodb
CONTAINER_MONGO_EXPRESS=set-mongo-express

# Ports (same as v0.2)
SSH_PORT=2222
APP_PORT=8080
MONGO_PORT=27017
MONGO_EXPRESS_PORT=8081

# Database Configuration (v0.2 names)
DB_NAME=set_game_db
DB_USER=set_app_user
DB_PASSWORD=SecurePassword123

# Collections (v0.2 names)
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores

# Keep other defaults...
```

### Step 2: Copy Code Without Changes

```bash
# Copy entire project as-is
cp -r ../v0.2/set_backend ./set_backend

# No code changes needed!
```

### Step 3: Deploy

```bash
# Reuse v0.2 SSH keys or generate new ones
cp ../v0.2/rust_dev_key* .
# or generate new: ssh-keygen -t ed25519 -f rust_dev_key -N ""

# Deploy
./deploy-v03.sh  # or deploy-v03.ps1
```

### Step 4: Test

1. **Connect via VS Code** (same config as v0.2)
2. **Open `/workspace/set_backend`** (same path)
3. **Run `cargo build`** (should work identically)

### Step 5: Migrate Data

```bash
# Same database name, so simple export/import
docker compose -f ../v0.2/docker-compose-v02.yml exec mongo-db \
  mongodump --db set_game_db --archive=/tmp/backup.archive

docker compose -f ../v0.2/docker-compose-v02.yml cp \
  mongo-db:/tmp/backup.archive ./backup.archive

docker compose cp ./backup.archive mongo-db:/tmp/backup.archive

docker compose exec mongo-db \
  mongorestore --archive=/tmp/backup.archive
```

**Benefit:** Drop-in replacement with .env configuration power!

---

## 🎨 Option 3: Hybrid Approach

Mix v0.2 and v0.3 naming for gradual transition.

### Step 1: Choose What to Keep/Change

**Example Decision Matrix:**

| Component | v0.2 Name | Keep or Change? | v0.3 Name |
|-----------|-----------|----------------|-----------|
| Project Dir | set_backend | Keep | set_backend |
| Database | set_game_db | **Change** | game_database |
| DB User | set_app_user | **Change** | game_user |
| SSH Port | 2222 | **Change** | 2223 (avoid conflict) |
| Collections | games/players/scores | Keep | games/players/scores |

### Step 2: Configure .env

```bash
cd v0.3
cp .env.example .env
```

**Edit .env with hybrid config:**

```bash
# Keep v0.2 project structure
PROJECT_DIR=set_backend

# Change database name (fresh start)
DB_NAME=game_database
DB_USER=game_user

# Change SSH port (run alongside v0.2)
SSH_PORT=2223

# Keep collection names
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores

# Change container names (avoid conflicts)
CONTAINER_RUST_DEV=set-rust-dev-v3
CONTAINER_MONGODB=set-mongodb-v3
```

### Step 3: Copy Code and Update

```bash
# Copy code
cp -r ../v0.2/set_backend ./set_backend

# Update only changed references
# E.g., if database name changed:
sed -i 's/set_game_db/game_database/g' ./set_backend/src/*.rs
```

### Step 4: Deploy and Test

```bash
./deploy-v03.sh

# Test on new port
# Connect to localhost:2223 (not 2222)
```

### Step 5: Run Both Versions Side-by-Side

**Benefit:** Compare old and new, migrate gradually

```bash
# v0.2 runs on ports: 2222, 8080, 27017, 8081
# v0.3 runs on ports: 2223, 8081, 27018, 8082

# Test both simultaneously
# Migrate when confident
```

---

## 🔍 Verification Checklist

After migration, verify:

### Docker Services

- [ ] All containers running: `docker compose ps`
- [ ] No error logs: `docker compose logs`
- [ ] Containers healthy: `docker compose ps` (State: Up)

### SSH Access

- [ ] Can connect via VS Code Remote-SSH
- [ ] Correct port (your SSH_PORT)
- [ ] SSH key authentication works
- [ ] Can open project directory

### Rust Environment

- [ ] `cargo --version` works
- [ ] `rustc --version` works
- [ ] Can build project: `cargo build`
- [ ] Can run project: `cargo run`

### Database

- [ ] MongoDB accessible from container
- [ ] Database exists with correct name
- [ ] User authentication works
- [ ] Collections created
- [ ] Mongo Express UI accessible

### Configuration

- [ ] .env values reflected in deployment
- [ ] Ports correct in service URLs
- [ ] Project directory named correctly
- [ ] Container names match .env

**Verification Commands:**

```bash
# Check containers
docker compose ps
docker compose logs mongo-db | tail -20

# Check environment inside container
docker compose exec rust-dev env | grep -E "(PROJECT_DIR|DB_NAME|SSH_PORT)"

# Test MongoDB
docker compose exec rust-dev mongosh mongodb://mongo-db:27017/$DB_NAME \
  -u $DB_USER -p $DB_PASSWORD --eval "db.stats()"

# Test Rust
docker compose exec rust-dev bash -c "cd /workspace/$PROJECT_DIR && cargo --version"
```

---

## 🐛 Troubleshooting Migration Issues

### Issue 1: Port Conflicts

**Symptom:** `Error starting userland proxy: bind: address already in use`

**Solution:**
```bash
# Check what's using the port
netstat -tuln | grep 2222

# Change port in .env
SSH_PORT=2223

# Redeploy
docker compose down
./deploy-v03.sh
```

### Issue 2: .env Not Loading

**Symptom:** Default values used despite .env file

**Solution:**
```bash
# Check .env syntax (no spaces around =)
cat .env | grep "="

# Correct:   PROJECT_DIR=myproject
# Wrong:     PROJECT_DIR = myproject

# Verify .env location (same directory as docker-compose-v03.yml)
ls -la .env

# Test configuration resolution
docker compose config | grep -A5 "environment:"
```

### Issue 3: Data Migration Failed

**Symptom:** Data not appearing in v0.3

**Solution:**
```bash
# Check if databases exist
docker compose exec mongo-db mongosh --eval "show dbs"

# Check collections
docker compose exec mongo-db mongosh $DB_NAME --eval "show collections"

# Re-run migration with correct database names
# See Step 7 in Option 1 above
```

### Issue 4: SSH Authentication Failed

**Symptom:** VS Code can't connect via SSH

**Solutions:**

```bash
# Check SSH service running
docker compose exec rust-dev service ssh status

# Check SSH port exposed
docker compose ps | grep rust-dev

# Verify key permissions (Linux/Mac)
chmod 600 rust_dev_key

# Test SSH manually
ssh -i rust_dev_key -p 2222 rustdev@localhost
```

### Issue 5: Code Compilation Errors

**Symptom:** `cargo build` fails after migration

**Solutions:**

```bash
# Clear cargo cache
docker compose exec rust-dev cargo clean

# Update dependencies
docker compose exec rust-dev cargo update

# Check for hardcoded references
grep -r "set_game_db" /workspace/$PROJECT_DIR/src/
grep -r "set_backend" /workspace/$PROJECT_DIR/src/

# Update found references to use environment variables
```

### Issue 6: Can't Find Project Directory

**Symptom:** `/workspace/set_backend` not found

**Solution:**
```bash
# Check PROJECT_DIR in .env
grep PROJECT_DIR .env

# List actual directory
docker compose exec rust-dev ls -la /workspace/

# Verify deployment created directory
# Should match PROJECT_DIR value
```

---

## 📊 Rollback Procedure

If migration fails and you need to revert:

### Step 1: Stop v0.3

```bash
cd v0.3
docker compose down
```

### Step 2: Restore v0.2

```bash
cd ../v0.2
docker compose up -d
```

### Step 3: Restore Data (if needed)

```bash
# If you backed up v0.2 data before migration
docker run --rm \
  -v $(pwd)/backup:/backup \
  -v dev_environment_v0.2_mongodb-data:/data \
  ubuntu \
  tar xzf /backup/mongodb-backup.tar.gz -C /
```

### Step 4: Reconnect VS Code

Update SSH config back to v0.2 settings and reconnect.

---

## 💡 Best Practices

### During Migration

1. **Backup Everything** - Data, code, configs
2. **Test in Isolation** - Don't delete v0.2 immediately
3. **Read Documentation** - Review README-v03.md thoroughly
4. **Use .env.example** - Start with template, customize gradually
5. **Verify Each Step** - Check services after each major step

### After Migration

1. **Document Changes** - Note custom .env settings
2. **Update Team** - Share migration experience
3. **Clean Up** - Remove v0.2 after successful migration
4. **Version Control** - Commit .env.example, not .env
5. **Regular Backups** - Establish backup routine for data

### Security

1. **Never Commit .env** - Contains secrets
2. **Change Default Passwords** - In .env file
3. **Restrict Port Access** - Firewall rules if needed
4. **Rotate SSH Keys** - Periodically update keys
5. **Review Permissions** - Ensure proper file permissions

---

## 📚 Additional Resources

### Documentation

- **README-v03.md** - Complete v0.3 documentation
- **VERSION.md** - Version 0.3 release notes
- **.env.example** - All configuration options

### Files to Review

- `docker-compose-v03.yml` - See environment variable usage
- `deploy-v03.sh` / `deploy-v03.ps1` - Deployment automation
- `.env.example` - Configuration template

### Useful Commands

```bash
# Show resolved configuration
docker compose config

# Check environment variables in container
docker compose exec rust-dev env

# View container logs
docker compose logs -f

# Restart services
docker compose restart

# Complete teardown
docker compose down -v
```

---

## 🎓 Learning Resources

### Understanding .env Files

- Simple key=value format
- No spaces around `=`
- Comments start with `#`
- One variable per line
- Used by docker-compose.yml

### Docker Compose Variable Substitution

```yaml
# Syntax: ${VARIABLE:-default}
container_name: ${CONTAINER_NAME:-default-name}

# Reads from:
# 1. Environment variable
# 2. .env file
# 3. Falls back to default
```

### Environment Variables in Rust

```rust
use std::env;

// Read environment variable with default
let db_name = env::var("DB_NAME")
    .unwrap_or_else(|_| "default_db".to_string());

// Read required variable (panic if missing)
let api_key = env::var("API_KEY")
    .expect("API_KEY must be set");
```

---

## ✅ Migration Complete Checklist

Before considering migration complete:

- [ ] All services running without errors
- [ ] Can connect via VS Code Remote-SSH
- [ ] Cargo commands work (build, run, test)
- [ ] MongoDB accessible and data present
- [ ] Mongo Express UI accessible
- [ ] Application code runs correctly
- [ ] Data migrated successfully (if applicable)
- [ ] Configuration matches requirements (.env values applied)
- [ ] Documentation updated (team notes, README updates)
- [ ] Backup of v0.2 exists and verified
- [ ] Team members informed about migration

---

## 📞 Support

If you encounter issues during migration:

1. **Review Troubleshooting Section** - Common issues covered
2. **Check Logs** - `docker compose logs`
3. **Verify Configuration** - `docker compose config`
4. **Test Components** - Isolate issue (SSH, MongoDB, Rust)
5. **Consult Documentation** - README-v03.md, VERSION.md

---

## 📝 Migration Timeline

**Typical Migration Schedule:**

| Phase | Duration | Activity |
|-------|----------|----------|
| Planning | 5 min | Choose migration option, review docs |
| Backup | 5 min | Backup data and code |
| Configuration | 5-10 min | Create and customize .env |
| Deployment | 5 min | Run deploy script |
| Code Updates | 5-15 min | Update hardcoded references (if needed) |
| Testing | 10-20 min | Verify all functionality |
| Data Migration | 5-10 min | Import existing data (if applicable) |
| Cleanup | 5 min | Remove v0.2 (after verification) |
| **Total** | **15-30 min** | Complete migration |

---

**Migration Version:** 1.0  
**For:** v0.2 → v0.3 transition  
**Last Updated:** December 2024

---

**Ready to migrate?** Choose your option above and follow the steps carefully. Good luck! 🚀
