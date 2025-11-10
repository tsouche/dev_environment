################################################################################
################################################################################
# Rust Backend Runtime - Version 0.5 (Test Environment)
# Minimal runtime container for pre-compiled backend executable
################################################################################
################################################################################
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

################################################################################
# Install Minimal Runtime Dependencies
################################################################################
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

################################################################################
# Install MongoDB Shell (mongosh) for debugging
################################################################################
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-mongosh && \
    rm -rf /var/lib/apt/lists/*

################################################################################
# User Configuration
################################################################################
ARG USERNAME=rustdev
ARG USER_UID=1026
ARG GROUPNAME=rustdevteam
ARG USER_GID=110

RUN groupadd --gid ${USER_GID} ${GROUPNAME} || true && \
    useradd --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash -m ${USERNAME} || true

################################################################################
# Application Setup
################################################################################
WORKDIR /app

# Copy the pre-compiled debug executable
# This file must be built before: cargo build (debug mode)
COPY set_backend /app/set_backend
RUN chmod +x /app/set_backend && \
    chown ${USER_UID}:${USER_GID} /app/set_backend

# Create data directory for potential file operations
RUN mkdir -p /data && chown ${USER_UID}:${USER_GID} /data

################################################################################
# Runtime Configuration
################################################################################
USER ${USERNAME}

ENV RUST_BACKTRACE=1
ENV RUST_LOG=debug

EXPOSE 8080

################################################################################
# Container Startup
################################################################################
# Run the application
CMD ["/app/set_backend"]
