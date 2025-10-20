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

We build the image which we call **rust-ubuntu-dev** by running from within from C:\\rustdev\container\, we run: 
```bash
    docker build -t rust-ubuntu-dev .
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
