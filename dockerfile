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
