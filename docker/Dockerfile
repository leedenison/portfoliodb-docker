# Multi-stage Dockerfile for PortfolioDB
FROM rust:1.81-slim AS base

# =============================================================================
# BASE STAGE - Production dependencies for PortfolioDB
# =============================================================================

# Switch to nightly Rust
RUN rustup install nightly && rustup default nightly

ARG UID=1100
ARG GID=1100

# Install required utilities for repository setup
RUN apt-get update && apt-get install -y lsb-release wget gpg ca-certificates

# Add PostgreSQL APT repository
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg \
    && apt-key add /usr/share/keyrings/postgresql-archive-keyring.gpg

RUN groupadd -g $GID postgres && \
    useradd -r -u $UID -g postgres -s /bin/bash postgres

# Install PostgreSQL and TimescaleDB dependencies
RUN apt-get update && apt-get install -y \
    postgresql-17 \
    postgresql-contrib-17 \
    postgresql-common \
    postgresql-client-17 \
    postgresql-17-cron \
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

# Drop the cluster since our data directory is mounted as a volume
RUN pg_dropcluster --stop 17 main

WORKDIR /opt/portfoliodb

RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/log/postgresql

# Copy service scripts and make them executable
COPY scripts/ /opt/portfoliodb/scripts/
RUN chmod +x /opt/portfoliodb/scripts/*.sh

# =============================================================================
# COMMON DEV STAGE - Development Dependencies and Build Tools
# =============================================================================
FROM base AS common-dev

# Install build dependencies for PortfolioDB
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-watch for development hot reloading
RUN cargo install cargo-watch

# =============================================================================
# INIT STAGE - Database Initialization
# =============================================================================
FROM common-dev AS init

CMD ["/opt/portfoliodb/scripts/init-db.sh"]

# =============================================================================
# TEST STAGE - Test Environment with shared logs
# =============================================================================
FROM common-dev AS test

# Create src mount directory
RUN mkdir -p /opt/portfoliodb/src

EXPOSE 50001 5432

CMD ["/opt/portfoliodb/scripts/test.sh"]

# =============================================================================
# DEVELOPMENT STAGE - Development Environment with Hot Reload
# =============================================================================
FROM common-dev AS dev

# Create src mount directory
RUN mkdir -p /opt/portfoliodb/src

EXPOSE 50001 5432

# cargo-watch.sh rebuilds the binary on demand
CMD ["/opt/portfoliodb/scripts/cargo-watch.sh"]