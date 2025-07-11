# Multi-stage Dockerfile for PortfolioDB
FROM rust:1.81-slim AS base

# =============================================================================
# BASE STAGE - PostgreSQL and TimescaleDB Installation
# =============================================================================

# Install required utilities for repository setup
RUN apt-get update && apt-get install -y lsb-release wget gpg ca-certificates

# Add PostgreSQL APT repository for version 17
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg \
    && apt-key add /usr/share/keyrings/postgresql-archive-keyring.gpg

# Install PostgreSQL and TimescaleDB dependencies
RUN apt-get update && apt-get install -y \
    postgresql-17 \
    postgresql-contrib \
    postgresql-common \
    postgresql-client-17 \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository and install TimescaleDB for PostgreSQL 17
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /usr/share/keyrings/timescaledb-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list \
    && apt-get update \
    && apt-get install -y timescaledb-2-postgresql-17 \
    && rm -rf /var/lib/apt/lists/*

# Remove the default cluster and re-create it
RUN pg_dropcluster --stop 17 main && \
    pg_createcluster 17 main

# =============================================================================
# DEVELOPMENT STAGE - Development Environment with Hot Reload
# =============================================================================
FROM base AS dev

# Install cargo-watch for development
RUN cargo install cargo-watch

WORKDIR /opt/portfoliodb

# Create necessary directories
RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/log/postgresql

# Copy service scripts
COPY scripts/ /opt/portfoliodb/scripts/

# Make scripts executable
RUN chmod +x /opt/portfoliodb/scripts/*.sh

EXPOSE 8080 5432

CMD ["/opt/portfoliodb/scripts/services.sh", "start"]

# =============================================================================
# PRODUCTION STAGE - Optimized Production Environment
# =============================================================================
FROM base AS prod

WORKDIR /opt/portfoliodb

# Create necessary directories
RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/lib/postgresql/data /var/log/postgresql

# Copy service scripts
COPY scripts/ /opt/portfoliodb/scripts/

# Make scripts executable
RUN chmod +x /opt/portfoliodb/scripts/*.sh

# Copy the PortfolioDB binary
COPY bin/portfoliodb /opt/portfoliodb/portfoliodb

# Create a non-root user
RUN useradd -r -s /bin/false portfoliodb && \
    chown -R portfoliodb:portfoliodb /opt/portfoliodb

USER portfoliodb

EXPOSE 8080

CMD ["/opt/portfoliodb/scripts/services.sh", "start"] 