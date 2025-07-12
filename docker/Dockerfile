# Multi-stage Dockerfile for PortfolioDB
FROM rust:1.81-slim AS base

# =============================================================================
# BASE STAGE - PostgreSQL and TimescaleDB Installation
# =============================================================================

# Switch to nightly Rust until we can use 2024 edition
RUN rustup install nightly && rustup default nightly

# Build arguments for user/group configuration
ARG POSTGRES_UID=1100
ARG POSTGRES_GID=1100

# Install required utilities for repository setup
RUN apt-get update && apt-get install -y lsb-release wget gpg ca-certificates

# Add PostgreSQL APT repository
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg \
    && apt-key add /usr/share/keyrings/postgresql-archive-keyring.gpg

# Create postgres user and group with specified UID/GID
RUN groupadd -g $POSTGRES_GID postgres && \
    useradd -r -u $POSTGRES_UID -g postgres -s /bin/bash postgres

# Install PostgreSQL and TimescaleDB dependencies
RUN apt-get update && apt-get install -y \
    postgresql-17 \
    postgresql-contrib-17 \
    postgresql-common \
    postgresql-client-17 \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository and install TimescaleDB
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /usr/share/keyrings/timescaledb-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list \
    && apt-get update \
    && apt-get install -y timescaledb-2-postgresql-17 \
    && apt-get remove --purge -y wget \
    && rm -rf /var/lib/apt/lists/*

# Remove the default cluster and re-create it
RUN pg_dropcluster --stop 17 main && \
    pg_createcluster 17 main

WORKDIR /opt/portfoliodb

RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/log/postgresql

# Copy service scripts and make them executable
COPY scripts/ /opt/portfoliodb/scripts/
RUN chmod +x /opt/portfoliodb/scripts/*.sh

# =============================================================================
# DEVELOPMENT STAGE - Development Environment with Hot Reload
# =============================================================================
FROM base AS dev

# Install build dependencies for PortfolioDB
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-watch for development hot reloading
RUN cargo install cargo-watch

# Create dev-specific directory
RUN mkdir -p /opt/portfoliodb/src

EXPOSE 50001 5432

# Use cargo-watch.sh as the main executable for dev stage
CMD ["/opt/portfoliodb/scripts/cargo-watch.sh", "start"]

# =============================================================================
# PRODUCTION STAGE - Optimized Production Environment
# =============================================================================
FROM base AS prod

# Create prod-specific directory
RUN mkdir -p /var/lib/postgresql/data

# Copy the PortfolioDB binary
COPY bin/portfoliodb /opt/portfoliodb/portfoliodb

# Create a non-root user
RUN useradd -r -s /bin/false portfoliodb && \
    chown -R portfoliodb:portfoliodb /opt/portfoliodb

USER portfoliodb

EXPOSE 50001

CMD ["/opt/portfoliodb/scripts/services.sh", "start"] 