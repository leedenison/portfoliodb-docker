#!/bin/bash

# PostgreSQL configuration script for PortfolioDB
# This script should be run as the postgres user

set -e

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dev}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev}"
POSTGRES_SUPERUSER="${POSTGRES_SUPERUSER:-portfoliodb}"
POSTGRES_SUPERUSER_PASSWORD="${POSTGRES_SUPERUSER_PASSWORD:-portfoliodb}"
POSTGRES_DB="${POSTGRES_DB:-portfoliodb}"

DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "=== PortfolioDB PostgreSQL Configuration ==="
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "=========================================="

# Function to create database and user
create_database_and_user() {
    echo "Creating database and user..."
    
    if [ -z "$POSTGRES_SUPERUSER_PASSWORD" ]; then
        echo "Setting superuser user password..."
        psql -c "ALTER USER $POSTGRES_SUPERUSER PASSWORD '$POSTGRES_SUPERUSER_PASSWORD';"
    fi
    
    # Create user if it doesn't exist
    psql -c "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER';" | grep -q 1 || {
        echo "Creating user $POSTGRES_USER..."
        psql -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
    }
    
    # Create database if it doesn't exist
    psql -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB" || {
        echo "Creating database $POSTGRES_DB..."
        psql -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"
    }
    
    # Grant privileges
    psql -c "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;"
    psql -c "GRANT ALL ON SCHEMA public TO $POSTGRES_USER;"
}

# Function to configure TimescaleDB extension
configure_timescaledb() {
    echo "Configuring TimescaleDB extension..."
    
    # Connect to the database and configure TimescaleDB as unified user
    psql -d $POSTGRES_DB <<-EOSQL
        -- Create the TimescaleDB extension
        CREATE EXTENSION IF NOT EXISTS timescaledb;
        
        -- Verify the extension is installed
        SELECT default_version, installed_version 
        FROM pg_available_extensions 
        WHERE name = 'timescaledb';
EOSQL
    
    echo "TimescaleDB extension configured successfully"
}

# Function to configure pg_cron extension
configure_pg_cron() {
    echo "Configuring pg_cron extension..."
    
    # First, create pg_cron extension in the postgres database (required)
    psql -d postgres <<-EOSQL
        -- Create the pg_cron extension in postgres database
        CREATE EXTENSION IF NOT EXISTS pg_cron;
        
        -- Verify the extension is installed
        SELECT default_version, installed_version 
        FROM pg_available_extensions 
        WHERE name = 'pg_cron';
EOSQL
    
    # Then, create pg_cron extension in the portfoliodb database
    psql -d $POSTGRES_DB <<-EOSQL
        -- Create the pg_cron extension
        CREATE EXTENSION IF NOT EXISTS pg_cron;
        
        -- Grant permissions to portfoliodb user for cron schema
        GRANT USAGE ON SCHEMA cron TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cron TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA cron TO $POSTGRES_USER;
        
        -- Set default privileges for future objects in cron schema
        ALTER DEFAULT PRIVILEGES IN SCHEMA cron GRANT ALL ON TABLES TO $POSTGRES_USER;
        ALTER DEFAULT PRIVILEGES IN SCHEMA cron GRANT ALL ON SEQUENCES TO $POSTGRES_USER;
        ALTER DEFAULT PRIVILEGES IN SCHEMA cron GRANT ALL ON FUNCTIONS TO $POSTGRES_USER;
        
        -- Verify the extension is installed
        SELECT default_version, installed_version 
        FROM pg_available_extensions 
        WHERE name = 'pg_cron';
EOSQL
    
    echo "pg_cron extension configured successfully"
}



# Main configuration logic
main() {
    create_database_and_user
    configure_timescaledb
    configure_pg_cron
}

main "$@" 