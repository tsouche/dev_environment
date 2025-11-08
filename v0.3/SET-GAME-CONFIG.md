# SET Game Backend - v0.3 Configuration Guide

**Project:** SET Card Game Backend  
**Version:** 0.3 Configuration  
**Type:** Project-Specific Example

---

## 📋 Overview

This guide shows how to use v0.3 with the specific configuration for the **SET card game backend** project, preserving all v0.2 naming conventions while gaining v0.3's flexibility.

---

## 🎯 Quick Start

### Option 1: Use Provided Configuration

```bash
# Navigate to v0.3 directory
cd /workspace/dev_environment/v0.3

# Copy the SET-specific configuration
cp .env.set_backend .env

# Deploy (uses SET game configuration)
./deploy-v03.sh
```

### Option 2: Customize Further

```bash
# Copy and edit
cp .env.set_backend .env
nano .env  # Change ports, passwords, etc.

# Deploy with your customizations
./deploy-v03.sh
```

---

## 📁 What You Get

### Configuration (.env.set_backend)

The provided `.env.set_backend` file configures:

```bash
# Project Structure
PROJECT_NAME=set_backend           # Cargo package name
PROJECT_DIR=set_backend            # Directory name (v0.2 compatible)

# Containers (v0.2 names)
CONTAINER_RUST_DEV=set-rust-dev
CONTAINER_MONGODB=set-mongodb
CONTAINER_MONGO_EXPRESS=set-mongo-express

# Ports (v0.2 compatible)
SSH_PORT=2222                      # VS Code Remote-SSH
APP_PORT=8080                      # SET game backend API
MONGO_PORT=27017                   # MongoDB
MONGO_EXPRESS_PORT=8081            # Mongo Express UI

# Database (v0.2 names)
DB_NAME=set_game_db                # SET game database
DB_USER=set_app_user               # Application user
DB_PASSWORD=set_app_password       # Application password

# Collections (SET game specific)
COLLECTION_1=games                 # Game sessions
COLLECTION_2=players               # Player profiles
COLLECTION_3=scores                # Game scores
```

### Directory Structure After Deployment

```
v0.3/
├── .env                           # Your active config (copied from .env.set_backend)
├── .env.example                   # Generic template
├── .env.set_backend               # SET game specific template
├── set_backend/                   # Your SET game code (created by script)
│   ├── Cargo.toml
│   └── src/
│       └── main.rs
├── docker/
│   └── mongo-init/
│       └── 01-init-set-db.js      # Initializes set_game_db
└── [other v0.3 files...]
```

---

## 🔧 Deployment Steps

### Step 1: Prepare Configuration

```bash
cd /workspace/dev_environment/v0.3

# Use SET game configuration
cp .env.set_backend .env

# Verify configuration
cat .env | grep -E "PROJECT_DIR|DB_NAME|COLLECTION"
```

**Expected Output:**
```
PROJECT_DIR=set_backend
DB_NAME=set_game_db
COLLECTION_1=games
COLLECTION_2=players
COLLECTION_3=scores
```

### Step 2: Deploy Environment

```bash
# Run deployment script
./deploy-v03.sh

# Wait for containers to start...
```

**What Happens:**
1. ✅ Loads `.env` file with SET game configuration
2. ✅ Creates `set_backend/` directory
3. ✅ Generates MongoDB init script with `set_game_db`
4. ✅ Creates collections: `games`, `players`, `scores`
5. ✅ Builds containers with `set-rust-dev`, `set-mongodb` names
6. ✅ Starts services on configured ports

### Step 3: Verify Deployment

```bash
# Check running containers
docker compose ps

# Expected containers:
# set-rust-dev        (SSH port 2222)
# set-mongodb         (MongoDB port 27017)
# set-mongo-express   (UI port 8081)
```

### Step 4: Add Your SET Game Code

```bash
# If you have existing SET game code from v0.2:
cp -r ../v0.2/set_backend/* ./set_backend/

# Or develop from scratch in the new environment
```

---

## 🔌 Connecting to the Environment

### VS Code Remote-SSH

1. **Update SSH Config** (`~/.ssh/config`):
   ```
   Host set-game-dev
       HostName localhost
       Port 2222
       User rustdev
       IdentityFile /path/to/v0.3/rust_dev_key
       StrictHostKeyChecking no
   ```

2. **Connect:**
   - Press `F1` in VS Code
   - Select "Remote-SSH: Connect to Host"
   - Choose "set-game-dev"

3. **Open Project:**
   - Open folder: `/workspace/set_backend`
   - Your SET game code is ready!

### MongoDB Access

#### Via Mongo Express (Web UI)
```
URL: http://localhost:8081
User: dev
Password: dev123
```

Navigate to: `set_game_db` → Collections (`games`, `players`, `scores`)

#### Via Command Line
```bash
# From host machine
mongosh mongodb://localhost:27017/set_game_db \
  -u set_app_user -p set_app_password

# Or from inside container
docker compose exec rust-dev mongosh mongodb://mongo-db:27017/set_game_db \
  -u set_app_user -p set_app_password
```

---

## 🎮 SET Game Backend Development

### Database Schema

The configuration creates three collections for the SET game:

#### 1. `games` Collection
Stores game sessions:
```javascript
{
  _id: ObjectId,
  game_id: String,
  players: [String],
  cards_on_table: Array,
  deck: Array,
  started_at: Date,
  ended_at: Date,
  status: String  // "in_progress", "completed"
}
```

#### 2. `players` Collection
Stores player information:
```javascript
{
  _id: ObjectId,
  player_id: String,
  username: String,
  email: String,
  games_played: Number,
  sets_found: Number,
  created_at: Date
}
```

#### 3. `scores` Collection
Stores game scores:
```javascript
{
  _id: ObjectId,
  score_id: String,
  game_id: String,
  player_id: String,
  points: Number,
  sets_found: Number,
  timestamp: Date
}
```

### Rust Code Example

```rust
// src/main.rs or src/database.rs
use mongodb::{Client, options::ClientOptions};
use std::env;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Read configuration from environment (set by docker-compose)
    let db_host = env::var("MONGODB_HOST").unwrap_or_else(|_| "mongo-db".to_string());
    let db_port = env::var("MONGODB_PORT").unwrap_or_else(|_| "27017".to_string());
    let db_name = env::var("MONGODB_DATABASE").unwrap_or_else(|_| "set_game_db".to_string());
    let db_user = env::var("MONGODB_USER").unwrap_or_else(|_| "set_app_user".to_string());
    let db_pass = env::var("MONGODB_PASSWORD").unwrap_or_else(|_| "set_app_password".to_string());
    
    // Build connection string
    let uri = format!("mongodb://{}:{}@{}:{}/{}", 
        db_user, db_pass, db_host, db_port, db_name);
    
    // Connect to MongoDB
    let client_options = ClientOptions::parse(&uri).await?;
    let client = Client::with_options(client_options)?;
    
    // Get database
    let db = client.database(&db_name);
    
    // Access collections
    let games = db.collection::<Game>("games");
    let players = db.collection::<Player>("players");
    let scores = db.collection::<Score>("scores");
    
    println!("Connected to SET game database: {}", db_name);
    
    Ok(())
}
```

---

## 🔄 Comparison: v0.2 vs v0.3

### What's the Same

✅ **All naming preserved:**
- Project directory: `set_backend`
- Database name: `set_game_db`
- Database user: `set_app_user`
- Collections: `games`, `players`, `scores`
- Container names: `set-rust-dev`, `set-mongodb`

✅ **Same ports:**
- SSH: 2222
- Application: 8080
- MongoDB: 27017
- Mongo Express: 8081

### What's Better in v0.3

✨ **All configured via .env:**
- No manual editing of docker-compose.yml
- Easy to share configuration
- Simple to customize

✨ **Easy to change:**
```bash
# Want different ports? Just edit .env:
SSH_PORT=2223
MONGO_PORT=27018

# Redeploy:
docker compose down
./deploy-v03.sh
```

✨ **Multi-environment ready:**
- Run v0.2 and v0.3 simultaneously
- Different ports avoid conflicts
- Independent databases

---

## 🚀 Advanced Usage

### Running Multiple SET Environments

You can run development and testing environments side-by-side:

**Development (.env.set_backend_dev):**
```bash
PROJECT_DIR=set_backend_dev
DB_NAME=set_game_db_dev
SSH_PORT=2222
MONGO_PORT=27017
CONTAINER_RUST_DEV=set-rust-dev
```

**Testing (.env.set_backend_test):**
```bash
PROJECT_DIR=set_backend_test
DB_NAME=set_game_db_test
SSH_PORT=2223
MONGO_PORT=27018
CONTAINER_RUST_DEV=set-rust-test
```

Deploy both:
```bash
# Development
cp .env.set_backend_dev .env
./deploy-v03.sh

# Testing (in another v0.3 copy)
cd ../v0.3-test
cp .env.set_backend_test .env
./deploy-v03.sh
```

### Database Backup/Restore

**Backup SET game data:**
```bash
docker compose exec mongo-db mongodump \
  --db set_game_db \
  --username set_app_user \
  --password set_app_password \
  --out /tmp/backup

docker compose cp mongo-db:/tmp/backup ./backup-$(date +%Y%m%d)
```

**Restore SET game data:**
```bash
docker compose cp ./backup-20241108 mongo-db:/tmp/backup

docker compose exec mongo-db mongorestore \
  --db set_game_db \
  --username set_app_user \
  --password set_app_password \
  /tmp/backup/set_game_db
```

---

## 🐛 Troubleshooting

### Issue: Port Conflicts

**Problem:** `Error: port 2222 already in use`

**Solution:**
```bash
# Option 1: Stop conflicting container
docker stop set-rust-dev

# Option 2: Change port in .env
echo "SSH_PORT=2223" >> .env
docker compose down
./deploy-v03.sh
```

### Issue: Database Connection Failed

**Problem:** Rust app can't connect to MongoDB

**Check:**
```bash
# 1. Verify MongoDB is running
docker compose ps

# 2. Test connection from container
docker compose exec rust-dev mongosh mongodb://mongo-db:27017/set_game_db \
  -u set_app_user -p set_app_password

# 3. Check environment variables in container
docker compose exec rust-dev env | grep MONGODB
```

### Issue: Can't SSH to Container

**Problem:** VS Code can't connect via SSH

**Solution:**
```bash
# 1. Check SSH service
docker compose exec rust-dev service ssh status

# 2. Verify key permissions
chmod 600 rust_dev_key

# 3. Test manually
ssh -i rust_dev_key -p 2222 rustdev@localhost
```

---

## 📊 Summary

### Configuration File

✅ `.env.set_backend` - Ready to use  
✅ All v0.2 names preserved  
✅ SET game specific collections  
✅ Complete documentation  

### Deployment

✅ One command: `cp .env.set_backend .env && ./deploy-v03.sh`  
✅ Creates `set_backend/` directory  
✅ Initializes `set_game_db` database  
✅ Sets up `games`, `players`, `scores` collections  

### Compatibility

✅ 100% compatible with v0.2 structure  
✅ Can migrate existing code directly  
✅ Same database schema  
✅ Same connection strings  

### Benefits Over v0.2

✨ Configuration via .env (no docker-compose editing)  
✨ Easy port changes  
✨ Simple customization  
✨ Multi-environment support  

---

## 📞 Next Steps

1. **Deploy:** `cp .env.set_backend .env && ./deploy-v03.sh`
2. **Connect:** VS Code Remote-SSH to localhost:2222
3. **Code:** Add your SET game logic to `/workspace/set_backend`
4. **Test:** Access MongoDB via http://localhost:8081
5. **Develop:** `cargo build && cargo run`

---

**Configuration:** `.env.set_backend`  
**Project:** SET Card Game Backend  
**Status:** Ready to Deploy  

🎮 Happy SET game development!
