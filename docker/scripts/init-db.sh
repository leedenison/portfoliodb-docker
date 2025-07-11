#!/bin/bash

# Database initialization script for PortfolioDB
# This script initializes the database with TimescaleDB extension and handles reset functionality

set -e  # Exit on any error

# Environment variables from docker-compose.yml
POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-/var/lib/postgresql/data}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-portfoliodb}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-portfoliodb_dev_password}"
POSTGRES_DB="${POSTGRES_DB:-portfoliodb}"
RESET_DB="${RESET_DB:-false}"

# Database connection string
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "=== PortfolioDB Database Initialization ==="
echo "Data directory: $POSTGRES_DATA_DIR"
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "Reset DB: $RESET_DB"
echo "=========================================="

# Function to check if database is initialized
is_database_initialized() {
    if [ -d "$POSTGRES_DATA_DIR" ] && [ "$(ls -A "$POSTGRES_DATA_DIR" 2>/dev/null)" ]; then
        echo "Database directory exists and contains data"
        return 0
    else
        echo "Database directory is empty or does not exist"
        return 1
    fi
}

# Function to initialize PostgreSQL cluster in the mounted volume
init_postgres_cluster() {
    echo "Initializing PostgreSQL cluster in $POSTGRES_DATA_DIR..."
    
    # Create data directory if it doesn't exist
    mkdir -p "$POSTGRES_DATA_DIR"
    chown postgres:postgres "$POSTGRES_DATA_DIR"
    
    # Check if cluster already exists in the data directory
    if [ -f "$POSTGRES_DATA_DIR/PG_VERSION" ]; then
        echo "PostgreSQL cluster already exists in $POSTGRES_DATA_DIR"
        # Start the cluster using the custom data directory
        su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D $POSTGRES_DATA_DIR start" || {
            echo "Starting existing PostgreSQL cluster..."
        }
    else
        echo "Creating new PostgreSQL cluster in $POSTGRES_DATA_DIR"
        # Initialize new cluster in the mounted volume
        su postgres -c "/usr/lib/postgresql/17/bin/initdb -D $POSTGRES_DATA_DIR"
        
        # Start the cluster
        su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D $POSTGRES_DATA_DIR start"
    fi
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h localhost -p 5432; do
        echo "Waiting for PostgreSQL..."
        sleep 1
    done
    
    echo "PostgreSQL is ready"
}

# Function to create database and user
create_database_and_user() {
    echo "Creating database and user..."
    
    # Set up postgres superuser password if not already set
    if [ -z "$POSTGRES_SUPERUSER_PASSWORD" ]; then
        export POSTGRES_SUPERUSER_PASSWORD="postgres_superuser_password"
        echo "Setting postgres superuser password..."
        su postgres -c "psql -c \"ALTER USER postgres PASSWORD '$POSTGRES_SUPERUSER_PASSWORD';\""
    fi
    
    # Create user if it doesn't exist
    su postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER';\"" | grep -q 1 || {
        echo "Creating user $POSTGRES_USER..."
        su postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\""
    }
    
    # Create database if it doesn't exist
    su postgres -c "psql -lqt" | cut -d \| -f 1 | grep -qw "$POSTGRES_DB" || {
        echo "Creating database $POSTGRES_DB..."
        su postgres -c "psql -c \"CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;\""
    }
    
    # Grant privileges
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;\""
    su postgres -c "psql -c \"GRANT ALL ON SCHEMA public TO $POSTGRES_USER;\""
}

# Function to configure TimescaleDB extension
configure_timescaledb() {
    echo "Configuring TimescaleDB extension..."
    
    # Connect to the database and configure TimescaleDB as postgres superuser
    su postgres -c "psql -d $POSTGRES_DB" <<-EOSQL
        -- Create the TimescaleDB extension
        CREATE EXTENSION IF NOT EXISTS timescaledb;
        
        -- Verify the extension is installed
        SELECT default_version, installed_version 
        FROM pg_available_extensions 
        WHERE name = 'timescaledb';
EOSQL
    
    echo "TimescaleDB extension configured successfully"
}

# Function to reset database
reset_database() {
    echo "Resetting database..."
    
    # Stop PostgreSQL if running
    if [ -f "$POSTGRES_DATA_DIR/postmaster.pid" ]; then
        su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D $POSTGRES_DATA_DIR stop" || true
    fi
    
    # Remove data directory
    if [ -d "$POSTGRES_DATA_DIR" ]; then
        echo "Removing existing data directory..."
        rm -rf "$POSTGRES_DATA_DIR"
    fi
    
    # Recreate data directory
    mkdir -p "$POSTGRES_DATA_DIR"
    chown postgres:postgres "$POSTGRES_DATA_DIR"
    
    # Initialize new PostgreSQL cluster
    echo "Initializing new PostgreSQL cluster..."
    su postgres -c "/usr/lib/postgresql/17/bin/initdb -D $POSTGRES_DATA_DIR"
    su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D $POSTGRES_DATA_DIR start"
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h localhost -p 5432; do
        echo "Waiting for PostgreSQL..."
        sleep 1
    done
    
    echo "Database reset completed"
}

# Function to ensure TimescaleDB is preloaded
ensure_timescaledb_preload() {
    CONF_FILE="$POSTGRES_DATA_DIR/postgresql.conf"
    if [ ! -f "$CONF_FILE" ]; then
        echo "PostgreSQL configuration file not found, will be created during initialization"
        return
    fi
    
    if ! grep -q "^shared_preload_libraries.*timescaledb" "$CONF_FILE"; then
        echo "Adding 'shared_preload_libraries = 'timescaledb'' to $CONF_FILE"
        echo "shared_preload_libraries = 'timescaledb'" >> "$CONF_FILE"
        # Restart cluster to apply changes
        su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D $POSTGRES_DATA_DIR restart"
    fi
}

# Main initialization logic
main() {
    echo "Starting database initialization..."
    
    # Check if we need to reset the database
    if [ "$RESET_DB" = "true" ]; then
        echo "RESET_DB is set to true, resetting database..."
        reset_database
    fi
    
    # Check if database is already initialized
    if is_database_initialized; then
        echo "Database appears to be already initialized"
        init_postgres_cluster
    else
        echo "Database not initialized, starting fresh..."
        init_postgres_cluster
    fi
    
    # Ensure TimescaleDB is preloaded
    ensure_timescaledb_preload
    
    # Create database and user
    create_database_and_user
    
    # Configure TimescaleDB extension
    configure_timescaledb
    
    echo "=== Database initialization completed successfully ==="
    echo "Database URL: $DATABASE_URL"
    echo "TimescaleDB extension is ready for use"
}

# Run main function
main "$@"
