# Multi-stage Dockerfile for PortfolioDB
FROM rust:1.81-slim as base

# =============================================================================
# BASE STAGE - PostgreSQL and TimescaleDB Installation
# =============================================================================

# Install PostgreSQL and TimescaleDB dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgresql-common \
    postgresql-client \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository and install TimescaleDB
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /usr/share/keyrings/timescaledb-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list \
    && apt-get update \
    && apt-get install -y timescaledb-2-postgresql-15 \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# DEVELOPMENT STAGE - Development Environment with Hot Reload
# =============================================================================
FROM base as dev

# Install cargo-watch for development
RUN cargo install cargo-watch

WORKDIR /opt/portfoliodb

# Create necessary directories
RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/lib/postgresql/data /var/log/postgresql

# Copy service scripts
COPY scripts/ /opt/portfoliodb/scripts/

# Make scripts executable
RUN chmod +x /opt/portfoliodb/scripts/*.sh

# Create PostgreSQL configuration
RUN echo '{\n\
  "host": "localhost",\n\
  "port": 5432,\n\
  "database": "portfoliodb",\n\
  "username": "portfoliodb",\n\
  "password": "portfoliodb_dev_password",\n\
  "ssl_mode": "disable"\n\
}' > /opt/portfoliodb/etc/postgresql.json

EXPOSE 8080 5432

CMD ["/opt/portfoliodb/scripts/services.sh", "start"]

# =============================================================================
# PRODUCTION STAGE - Optimized Production Environment
# =============================================================================
FROM base as prod

WORKDIR /opt/portfoliodb

# Create necessary directories
RUN mkdir -p /opt/portfoliodb/etc /opt/portfoliodb/scripts /var/lib/postgresql/data /var/log/postgresql

# Copy service scripts
COPY scripts/ /opt/portfoliodb/scripts/

# Make scripts executable
RUN chmod +x /opt/portfoliodb/scripts/*.sh

# Copy the PortfolioDB binary
COPY bin/portfoliodb /opt/portfoliodb/portfoliodb

# Create PostgreSQL configuration
RUN echo '{\n\
  "host": "localhost",\n\
  "port": 5432,\n\
  "database": "portfoliodb",\n\
  "username": "portfoliodb",\n\
  "password": "portfoliodb_prod_password",\n\
  "ssl_mode": "disable"\n\
}' > /opt/portfoliodb/etc/postgresql.json

# Create a non-root user
RUN useradd -r -s /bin/false portfoliodb && \
    chown -R portfoliodb:portfoliodb /opt/portfoliodb

USER portfoliodb

EXPOSE 8080

CMD ["/opt/portfoliodb/scripts/services.sh", "start"] 