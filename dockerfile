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

# Define ARG variables BEFORE the user creation RUN command
ARG USERNAME=rustdev
ARG USER_UID=1026
ARG GROUPNAME=rustdevteam
ARG USER_GID=110
ARG PASSWORD=Hp77M&zzu\$JoG1

# Create 'rustdev' user with its password, and add it to the sudo group
RUN groupadd --gid ${USER_GID} ${GROUPNAME} || true && \
    useradd --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash -m ${USERNAME} || true && \
    echo "${USERNAME}:${PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Set the working directory
WORKDIR /home/${USERNAME}

# Install Rust via rustup for the 'rustdev' user and ensure toolchain is set
USER ${USERNAME}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    . /home/${USERNAME}/.cargo/env && \
    /home/${USERNAME}/.cargo/bin/rustup default stable && \
    /home/${USERNAME}/.cargo/bin/cargo --version && \
    /home/${USERNAME}/.cargo/bin/rustc --version && \
    echo '. /home/${USERNAME}/.cargo/env' >> /home/${USERNAME}/.bashrc && \
    echo '. /home/${USERNAME}/.cargo/env' >> /home/${USERNAME}/.profile

# Add Cargo to PATH for the container's default environment
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# Shift back to 'root' user and configure SSH
USER root
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Expose the SSH port
EXPOSE 22

# Create a shared directory for the code: it will be mounted as a volume
RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# Default command: run SSH server
CMD ["/usr/sbin/sshd", "-D"]
