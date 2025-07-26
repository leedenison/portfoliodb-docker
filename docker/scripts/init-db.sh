#!/bin/bash

# Database initialization script for PortfolioDB

set -e

POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-/var/lib/postgresql/17/main}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dev}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev}"
POSTGRES_SUPERUSER="${POSTGRES_SUPERUSER:-portfoliodb}"
POSTGRES_SUPERUSER_PASSWORD="${POSTGRES_SUPERUSER_PASSWORD:-portfoliodb}"
POSTGRES_DB="${POSTGRES_DB:-portfoliodb}"
DB_ACTION="${DB_ACTION:-init}"

# Extract cluster name from data directory path
CLUSTER_NAME=$(basename "$POSTGRES_DATA_DIR")
POSTGRES_VERSION="17"

DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "=== PortfolioDB Database Initialization ==="
echo "Data directory: $POSTGRES_DATA_DIR"
echo "Cluster name: $CLUSTER_NAME"
echo "PostgreSQL version: $POSTGRES_VERSION"
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "DB Action: $DB_ACTION"
echo "=========================================="

is_database_initialized() {
    if [ -d "$POSTGRES_DATA_DIR" ] && [ "$(ls -A "$POSTGRES_DATA_DIR" 2>/dev/null)" ]; then
        echo "Database directory exists and contains data"
        return 0
    else
        echo "Database directory is empty or does not exist"
        return 1
    fi
}

init_database() {
    echo "Initializing PostgreSQL cluster in $POSTGRES_DATA_DIR..."
    
    # Check if cluster already exists in the data directory
    if [ -f "$POSTGRES_DATA_DIR/PG_VERSION" ]; then
        echo "PostgreSQL cluster already exists in $POSTGRES_DATA_DIR"
    else
        echo "Creating new PostgreSQL cluster in $POSTGRES_DATA_DIR"
        pg_createcluster $POSTGRES_VERSION $CLUSTER_NAME -d "$POSTGRES_DATA_DIR" --encoding=UTF8 --locale=C
    fi
    
    pg_ctlcluster $POSTGRES_VERSION $CLUSTER_NAME start
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h localhost -p 5432; do
        echo "Waiting for PostgreSQL..."
        sleep 1
    done
    
    echo "PostgreSQL is ready"
}

# Function to delete database data
delete_database() {
    echo "Deleting database data..."
    
    if pg_lsclusters | grep -q "$POSTGRES_VERSION/$CLUSTER_NAME"; then
        echo "Stopping PostgreSQL cluster..."
        pg_ctlcluster $POSTGRES_VERSION $CLUSTER_NAME stop || true
        echo "Dropping PostgreSQL cluster..."
        pg_dropcluster $POSTGRES_VERSION $CLUSTER_NAME --stop
        echo "PostgreSQL cluster dropped"
    else
        echo "PostgreSQL cluster does not exist"
    fi
}

configure_database() {
    echo "Starting database configuration..."
    su postgres -c "/opt/portfoliodb/scripts/configure-postgres.sh"
    echo "Database configuration completed"
}

run_migrations() {
    echo "Starting database migrations..."
    su postgres -c "/opt/portfoliodb/scripts/run-migrations.sh"
    echo "Database migrations completed"
}

# Function to ensure TimescaleDB and pg_cron are preloaded
ensure_extensions_preload() {
    CONF_FILE="/etc/postgresql/17/main/postgresql.conf"
    if [ ! -f "$CONF_FILE" ]; then
        echo "PostgreSQL configuration file not found"
        exit 1
    fi
    
    if grep -q "^shared_preload_libraries" "$CONF_FILE"; then
        echo "Setting shared_preload_libraries to 'timescaledb,pg_cron'"
        sed -i "s/^shared_preload_libraries = '\([^']*\)'/shared_preload_libraries = 'timescaledb,pg_cron'/" "$CONF_FILE"
    else
        echo "Adding 'shared_preload_libraries = 'timescaledb,pg_cron'' to $CONF_FILE"
        echo "shared_preload_libraries = 'timescaledb,pg_cron'" >> "$CONF_FILE"
    fi
    
    # Add cron.database_name setting for pg_cron
    if ! grep -q "^cron\.database_name" "$CONF_FILE"; then
        echo "Adding 'cron.database_name = '$POSTGRES_DB'' to $CONF_FILE"
        echo "cron.database_name = '$POSTGRES_DB'" >> "$CONF_FILE"
    fi
    
    # Restart cluster to apply changes
    pg_ctlcluster $POSTGRES_VERSION $CLUSTER_NAME restart
}



# Main initialization logic
main() {
    # Handle different DB_ACTION values
    case "$DB_ACTION" in
        "delete")
            delete_database
            ;;
        "reset")
            delete_database
            init_database
            ensure_extensions_preload
            configure_database
            run_migrations
            ;;
        "init")
            # Check if database is already initialized
            if is_database_initialized; then
                echo "Database appears to be already initialized"
            else
                init_database
                ensure_extensions_preload
                configure_database
                run_migrations
            fi
            ;;
        *)
            echo "Error: Invalid DB_ACTION value '$DB_ACTION'. Valid values are: init, delete, reset"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
