################################################################################
# SET Backend Development Environment
# Base: tsouche/rust_dev_container:v0.5.0
# 
# The base image already provides:
# - Ubuntu 22.04 LTS
# - Rust stable toolchain (via rustup)
# - Build tools (gcc, cmake, pkg-config, libssl-dev)
# - MongoDB Shell (mongosh)
# - SSH server configured with host keys
# - VS Code extensions auto-install
# - User rustdev (UID 1026, GID 110)
################################################################################
FROM tsouche/rust_dev_container:v0.5.0

# Override with local user's SSH public key
# This allows each machine/user to have their own SSH access
USER root
COPY authorized_keys /home/rustdev/.ssh/authorized_keys
RUN chown 1026:110 /home/rustdev/.ssh/authorized_keys && \
    chmod 600 /home/rustdev/.ssh/authorized_keys

WORKDIR /workspace
USER root

CMD ["/usr/sbin/sshd", "-D"]
