FROM ubuntu:24.04

# Mettre à jour les paquets et installer les dépendances de base
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

# Créer l'utilisateur rustdev avec un mot de passe défini
ARG USERNAME=rustdev
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG PASSWORD=Hp77M&zzu\$JoG1

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME:$PASSWORD" | chpasswd \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

# Configurer le répertoire de travail
WORKDIR /home/$USERNAME

# Installer Rust via rustup pour l'utilisateur rustdev
USER $USERNAME
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# Ajouter Cargo au PATH
ENV PATH="/home/$USERNAME/.cargo/bin:${PATH}"

# Revenir à root pour configurer SSH
USER root

# Configurer le serveur SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Exposer le port SSH
EXPOSE 22

# Créer un répertoire partagé pour le code (sera monté en volume)
RUN mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace

# Commande par défaut : démarrer SSH
CMD ["/usr/sbin/sshd", "-D"]
