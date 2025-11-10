################################################################################
################################################################################
# Rust Backend Runtime - Version 0.6.0 (Test Environment)
# Minimal runtime container for pre-compiled backend executable
# Base image: tsouche/set_backend_testprod provides Ubuntu 22.04 runtime
################################################################################
################################################################################
FROM tsouche/set_backend_testprod:v0.6.0

################################################################################
# Install MongoDB Shell for testing/debugging
################################################################################
USER root
RUN apt-get update && apt-get install -y gnupg && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-mongosh && \
    rm -rf /var/lib/apt/lists/*

################################################################################
# Application Setup
################################################################################
# Copy the pre-compiled debug executable
# This file must be built before: cargo build (debug mode)
COPY set_backend /app/set_backend
RUN chmod +x /app/set_backend && \
    chown 1026:100 /app/set_backend

################################################################################
# Runtime Configuration
################################################################################
USER thierry

ENV RUST_LOG=debug

################################################################################
# Container Startup
################################################################################
# Run the application
CMD ["/app/set_backend"]
