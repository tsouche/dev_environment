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

The dockerfile is located in C:\rustdev\container\

## Deploy the container using Docker Desktop

We build the image which we call **```rust-ubuntu-dev```** by running from within ```C:\\rustdev\container\```: 
```bash
    docker build -t rust-ubuntu-dev:0.1.0 .
```

We then launch the container, exposing the port 2222 for SSH connexion:
```
    docker run -d \
      -p 2222:22 \
      -v C:/rustdev/projects:/workspace \
      --name rust-dev-container \
      rust-ubuntu-dev
```

The code will be persisted in C:\rust-dev\projects\, which is mapped into /workspace (which belongs to 'rustdev' user).

## VS code configuration

Nous utilisons l'extension Remote - SSH de VS Code pour connecter l'IDE comme client à ce "serveur" (le container).

### Étape 2.1 : Installer les extensions nécessaires dans VS Code

Ouvrez VS Code sur Windows 11.
Allez dans l'onglet Extensions (Ctrl+Shift+X).
Installez "Remote - SSH" (par Microsoft). Cela inclut le pack Remote Development si nécessaire.
(Optionnel mais recommandé pour Rust) : Installez "rust-analyzer" (par rust-lang). Vous l'installerez aussi sur le remote plus tard.

### Étape 2.2 : Configurer la connexion SSH

Ouvrez le fichier de configuration SSH : Appuyez sur Ctrl+Shift+P (Command Palette), tapez "Remote-SSH: Open Configuration File", et sélectionnez le fichier par défaut (généralement C:\Users\VOTRE_USER\.ssh\config).
Ajoutez ce bloc au fichier (créez-le s'il n'existe pas) :
textHost rust-container
    HostName localhost
    Port 2222
    User root

Sauvegardez. Cela définit une connexion nommée "rust-container" vers localhost:2222 (le port mappé du container).

### Étape 2.3 : Se connecter au container

Dans la Command Palette (Ctrl+Shift+P), tapez "Remote-SSH: Connect to Host".
Sélectionnez "rust-container".
Entrez le mot de passe que vous avez défini dans le Dockerfile (ex. 'monmotdepasse').
VS Code se connecte : Vous verrez un indicateur vert en bas à gauche indiquant "SSH: rust-container".

### Étape 2.4 : Ouvrir un dossier et configurer pour Rust

Une fois connecté, VS Code vous demande d'ouvrir un dossier. Choisissez /workspace (le volume monté, où votre code est synchronisé).
Installez les extensions remote : Dans l'onglet Extensions, cherchez "rust-analyzer" et installez-la sur le remote (il y a un bouton "Install in SSH: rust-container").
Créez un projet Rust test : Ouvrez un terminal dans VS Code (Ctrl+`), et exécutez :
textcd /workspace
cargo new mon_app_rust
cd mon_app_rust
cargo run

VS Code devrait maintenant offrir l'autocomplétion, le linting, et le debugging pour Rust via rust-analyzer.


Notes sur l'utilisation :

Votre code est dans le dossier local monté (C:/chemin/vers/votre/projet), mais édité depuis le container (env Linux).
Pour debugger : Ajoutez un fichier .vscode/launch.json dans votre projet avec une config Rust standard (rust-analyzer l'aide à générer).
Si le container s'arrête, relancez-le avec docker start rust-dev-container et reconnectez-vous.
Sécurité : Comme c'est local, pas de souci majeur, mais changez le mot de passe. Pour production, utilisez des clés SSH au lieu d'un password.
Personnalisation : Ajoutez plus d'outils dans le Dockerfile (ex. apt-get install -y vim ou d'autres paquets), puis rebuild l'image.

Si vous rencontrez des erreurs (ex. port en conflit), ajustez le port mappé (ex. -p 2223:22). Testez et adaptez ! Si besoin de plus de détails, fournissez les logs d'erreur.





















### Procedure to Set Up a Rust Development Environment in a Linux Container on Windows 11 Using Docker and VS Code

This guide compiles and details all the steps from our previous discussions into a single, comprehensive procedure in English. It assumes you are using a Windows 11 laptop with Docker Desktop already installed (if not, download it from the official Docker website and enable WSL integration during setup). We will use VS Code as the IDE in "client" mode, connecting remotely to a Linux container (based on Ubuntu) running via Docker Desktop. The container will be pre-configured with Rust tooling, an SSH server for remote access, and a non-root user `rustdev` for security.

The Dockerfile will be placed in `C:\rustdev\container`. The workspace (where your code lives) will be mounted from `C:\rustdev\projects` on your host to `/workspace` in the container, ensuring your code is persisted and synchronized.

We'll cover:
- Writing the Dockerfile
- Building the Docker image
- Deploying (running) the container
- Installing VS Code extensions
- Connecting VS Code to the container
- Testing the setup
- Creating a new project by cloning a Git repo inside VS Code (in the container)

Follow each step sequentially. If you encounter errors, check Docker logs with `docker logs rust-dev-container` or provide details for troubleshooting.

#### Step 1: Write the Dockerfile
1. Create the directory for the Dockerfile on your Windows host:
   - Open File Explorer.
   - Navigate to `C:\` and create a new folder named `rustdev`.
   - Inside `rustdev`, create a subfolder named `container`.
   - Your path should now be `C:\rustdev\container`.

2. Create the Dockerfile file:
   - Open VS Code (or Notepad) on your Windows host.
   - Create a new file named `Dockerfile` (no extension) in `C:\rustdev\container`.
   - Copy and paste the following content into the file exactly as shown. This Dockerfile creates an Ubuntu 24.04-based image with Rust installed for the user `rustdev`, SSH configured, and essential tools like Git. The password for `rustdev` is set to `Hp77M&zzu$JoG1` (a strong password; change it if needed, but update references accordingly).

```
FROM ubuntu:24.04

# Update packages and basic dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl \
    build-essential \
    libssl-dev \
    pkg-config \
    git \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# create 'rustdev' user with its password, and add it to the sudo group
ARG USERNAME=rustdev
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG PASSWORD=Hp77M&zzu\$JoG1

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME:$PASSWORD" | chpasswd \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

# Set teh working directory
WORKDIR /home/$USERNAME

# Install Rust via rustup for the 'rustdev' user
USER $USERNAME
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# add Cargo to PATH
ENV PATH="/home/$USERNAME/.cargo/bin:${PATH}"

# Shift back to 'root' user and configure SSH
USER root
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Expose the SSH port
EXPOSE 22

# Create a shared directory for the code: it will be mounted as a volume
RUN mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace

# Default command: run SSH server
CMD ["/usr/sbin/sshd", "-D"]
```

3. Save the file. Note: There is a typo in the original ("Set teh working directory" should be "Set the working directory"), but it doesn't affect functionality as it's a comment. You can fix it if desired.

#### Step 2: Build the Docker Image
1. Open a command prompt (PowerShell or CMD) on your Windows host.
2. Navigate to the directory containing the Dockerfile:
   ```
   cd C:\rustdev\container
   ```
3. Build the image:
   ```
   docker build -t rust-ubuntu-dev .
   ```
   - This command builds an image named `rust-ubuntu-dev`.
   - The process may take 5-10 minutes the first time due to package downloads.
   - Verify the build succeeded with `docker images` (you should see `rust-ubuntu-dev` listed).

#### Step 3: Deploy (Run) the Container
1. Create the workspace directory on your host if it doesn't exist:
   - In File Explorer, navigate to `C:\rustdev` and create a subfolder named `projects`.
   - Your code will be stored here and mounted into the container.

2. Run the container:
   - In the same command prompt, execute:
     ```
     docker run -d -p 2222:22 -v C:\rustdev\projects:/workspace --name rust-dev-container rust-ubuntu-dev
     ```
     - `-d`: Runs in detached (background) mode.
     - `-p 2222:22`: Maps the container's SSH port (22) to port 2222 on your host (to avoid conflicts).
     - `-v C:\rustdev\projects:/workspace`: Mounts your local `projects` folder to `/workspace` in the container for code persistence.
     - `--name rust-dev-container`: Names the container for easy reference.
   - Verify it's running: `docker ps` (look for `rust-dev-container` in the list).
   - If it stops, restart with `docker start rust-dev-container`.

#### Step 4: Install VS Code Extensions
1. Open VS Code on your Windows 11 host.
2. Go to the Extensions view: Press `Ctrl+Shift+X` or click the Extensions icon in the sidebar.
3. Search for and install:
   - "Remote - SSH" by Microsoft (this enables remote connections; it may prompt to install the Remote Development pack).
4. (Recommended for Rust development) Search for and install "rust-analyzer" by rust-lang (this provides autocompletion, linting, and debugging for Rust). You'll install it on the remote side later.

#### Step 5: Connect VS Code to the Container
1. Configure SSH in VS Code:
   - Press `Ctrl+Shift+P` to open the Command Palette.
   - Type "Remote-SSH: Open Configuration File" and select the default SSH config file (usually `C:\Users\YourUsername\.ssh\config`; create it if it doesn't exist).
   - Add the following block to the file:
     ```
     Host rust-container
         HostName localhost
         Port 2222
         User rustdev
     ```
   - Save the file. This sets up a connection profile to the container's SSH server.

2. Connect to the remote host:
   - In the Command Palette (`Ctrl+Shift+P`), type "Remote-SSH: Connect to Host".
   - Select "rust-container".
   - Enter the password: `Hp77M&zzu$JoG1` (you'll be prompted).
   - VS Code will connect; look for a green indicator in the bottom-left corner saying "SSH: rust-container".

3. Open the workspace folder:
   - Once connected, VS Code prompts to open a folder. Select `/workspace` (this is the mounted directory where your code lives).
   - Install remote extensions: In the Extensions view, search for "rust-analyzer" and click "Install in SSH: rust-container" (this installs it on the remote side for better performance).

(Optional: For passwordless login in the future, set up SSH keys. Generate a key pair on your host with `ssh-keygen`, then copy the public key to the container using `docker cp` or `ssh-copy-id`.)

#### Step 6: Test the Setup
1. Open a terminal in VS Code: Press `Ctrl+`` (backtick) or go to Terminal > New Terminal. It should open in the remote container (check the prompt shows something like `rustdev@...`).
2. Verify the user and environment:
   ```
   whoami  # Should output: rustdev
   pwd     # Should output: /workspace (or cd /workspace first)
   rustc --version  # Should show the Rust compiler version (e.g., rustc 1.81.0)
   cargo --version  # Should show Cargo version
   git --version    # Should confirm Git is installed
   ```
3. Create a simple Rust test project:
   ```
   cargo new test_rust_app
   cd test_rust_app
   cargo build  # Builds the app
   cargo run    # Runs it (should print "Hello, world!")
   ```
4. Check file synchronization: Create or edit a file in `/workspace` (e.g., via VS Code), then check it appears/updates in `C:\rustdev\projects` on your host.
5. Disconnect and reconnect: In VS Code, click the remote indicator and select "Close Remote Connection". Reconnect as in Step 5 to ensure persistence.

If everything works, your Rust dev environment is ready.

#### Step 7: Create a New Project by Cloning a Git Repo Inside VS Code (in the Container)
1. Ensure you're connected to the remote container in VS Code (from Step 5).
2. Open a terminal in VS Code (`Ctrl+``) and navigate to the workspace:
   ```
   cd /workspace
   ```
3. Clone a Git repo:
   - For example, to clone a sample Rust repo (replace with your own URL, e.g., from GitHub):
     ```
     git clone https://github.com/rust-lang/rust-by-example.git my_rust_project
     ```
     - This clones the repo into `/workspace/my_rust_project`.
   - If the repo requires authentication (e.g., private repo), set up Git credentials or SSH keys in the container first (e.g., `git config --global user.name "Your Name"` and use `ssh-keygen` for keys).

4. Open the project in VS Code:
   - In the File Explorer sidebar (remote side), navigate to `/workspace/my_rust_project`.
   - Right-click and select "Open Folder" (or use File > Open Folder and select the path).
   - VS Code reloads with the project open. rust-analyzer should activate automatically for Rust features.

5. Build and run the project:
   - In the terminal:
     ```
     cd my_rust_project
     cargo build
     cargo run  # Or follow the repo's instructions
     ```
   - Use VS Code's debugger: Press `F5` or go to Run > Start Debugging (rust-analyzer helps configure `launch.json` if needed).

6. Commit changes (optional):
   - Edit files in VS Code.
   - In the terminal: `git add .`, `git commit -m "Initial changes"`, `git push` (if applicable).

Your code is now deployed directly in the container's `/workspace`, synchronized with your host, and ready for development. For multiple projects, create subfolders in `/workspace`. If you stop the container, your code persists on the host. Restart as needed with `docker start rust-dev-container`.
