################################################################################
################################################################################
# Rust Backend Runtime - Version 0.7.0 (Production Environment)
# Minimal runtime container for pre-compiled backend executable
# Base image: tsouche/set_backend_testprod provides Ubuntu 22.04 (minimal runtime)
# Note: Production does NOT include mongosh (not needed in prod)
################################################################################
################################################################################
FROM tsouche/set_backend_testprod:v0.6.0

################################################################################
# Application Setup
################################################################################
# Copy the pre-compiled release executable
# This file must be built before: cargo build --release
COPY --chown=1026:100 --chmod=755 set_backend /app/set_backend

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
