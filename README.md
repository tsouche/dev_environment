# Win11 development environment

This project is about delivering a versionned Dev environment to code on Win11:
- I use VS Code running on Win11 as IDE
- I deploy a Ubuntu container with Docker Desktop on Win11
- In this container, I deploy SSH and rust toolchain

I then use VS Code to access the container, thus benefitting from the best of both worlds:
- I can do my usual work on Win11, using mostly office tools
- and I dev within a Linux environment
 
## Directories

    |-----------|-------------------------|------------------|
    |           | on the laptop           | in the container |
    |-----------|-------------------------|------------------|
    | container | C:\rust-dev\container\  |                  |  
    | code      | C:\rust-dev\projects\   | /workspace/      | 
    |-----------|-------------------------|------------------|

## Create the container image

The container is defined with a dockerfile, in order to garantee version control at any moment.
- the base image is **Ubuntu 24.04**: the last LTS image 
- create a non-root user: **'rustdev'**
- define tits password: '**Hp77M&zzu$JoG1**'
- install **Rust** for this user
- install and configure a **open-ssh server** to allow rustdev to connect
- add rustdev to the **sudo group** (will give more flexibility later, in need be)
- use **/workspace** as code directory: we will pesist the data (on the laptop) via a volume

The dockerfile is located in ```C:\rustdev\container\```

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
2. Copy the public key to the container:
   - Ensure the container is running (`docker ps` to check; start with `docker start rust-dev-container` if needed).
   - Run:
     ```bash
         docker exec -it rust-dev-container mkdir -p /home/rustdev/.ssh
         cat C:\Users\YourUsername\.ssh\id_ed25519.pub | docker exec -i rust-dev-container sh -c 'cat >> /home/rustdev/.ssh/authorized_keys'
         docker exec -it rust-dev-container chown -R rustdev:rustdevteam /home/rustdev/.ssh
         docker exec -it rust-dev-container chmod 700 /home/rustdev/.ssh
         docker exec -it rust-dev-container chmod 600 /home/rustdev/.ssh/authorized_keys
     ```
3. Test passwordless connection: Run `ssh rust-container` in PowerShell (you should connect without a password prompt).

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
   - "crates" by serayuzgur: For managing Rust dependencies.
   - "Better TOML" by bungcip: For editing Cargo.toml files.
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
