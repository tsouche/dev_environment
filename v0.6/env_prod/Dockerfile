################################################################################
################################################################################
# Rust Backend Runtime - Version 0.6.0 (Production Environment)
# Minimal runtime container for pre-compiled backend executable
# Base image: tsouche/set_backend_testprod provides Ubuntu 22.04 + mongosh
################################################################################
################################################################################
FROM tsouche/set_backend_testprod:v0.6.0

################################################################################
# Application Setup
################################################################################
# Copy the pre-compiled release executable
# This file must be built before: cargo build --release
COPY set_backend /app/set_backend
RUN chmod +x /app/set_backend && \
    chown 1026:100 /app/set_backend

################################################################################
# Runtime Configuration
################################################################################
USER thierry

ENV RUST_LOG=info

################################################################################
# Container Startup
################################################################################
# Run the application
CMD ["/app/set_backend"]
