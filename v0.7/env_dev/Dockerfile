################################################################################
# SET Backend Development Environment
# Base: tsouche/rust_devcontainer:v0.5.0
# 
# The base image already provides:
# - Ubuntu 22.04 LTS
# - Rust stable toolchain (via rustup)
# - Build tools (gcc, cmake, pkg-config, libssl-dev)
# - MongoDB Shell (mongosh)
# - SSH server configured
# - VS Code extensions auto-install
# - User rustdev (UID 1026, GID 110)
################################################################################
FROM tsouche/rust_devcontainer:v0.5.0

# The base image is complete and ready for SET Backend development
# No additional configuration needed!

WORKDIR /workspace
USER rustdev

CMD ["/usr/sbin/sshd", "-D"]
