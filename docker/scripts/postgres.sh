#!/bin/bash

# PostgreSQL service script for PortfolioDB
# Usage: postgres.sh {start|stop|status|restart}

POSTGRES_DATA_DIR="/var/lib/postgresql/data"
POSTGRES_LOG_DIR="/var/log/postgresql"
POSTGRES_CLUSTER="15 main"

# Function to start PostgreSQL
start_postgres() {
    echo "Starting PostgreSQL..."
    
    # Create directories if they don't exist
    mkdir -p "$POSTGRES_DATA_DIR" "$POSTGRES_LOG_DIR"
    
    # Start PostgreSQL cluster
    pg_ctlcluster 15 main start
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h localhost -p 5432; do
        echo "Waiting for PostgreSQL..."
        sleep 1
    done
    
    # Initialize database if needed
    if ! su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw portfoliodb"; then
        echo "Initializing PortfolioDB database..."
        su - postgres -c "psql -c \"CREATE USER portfoliodb WITH PASSWORD 'portfoliodb_dev_password';\""
        su - postgres -c "psql -c \"CREATE DATABASE portfoliodb OWNER portfoliodb;\""
    fi
    
    # Enable TimescaleDB extension
    echo "Enabling TimescaleDB extension..."
    su - postgres -c "psql -d portfoliodb -c \"CREATE EXTENSION IF NOT EXISTS timescaledb;\""
    
    echo "PostgreSQL started successfully"
}

# Function to stop PostgreSQL
stop_postgres() {
    echo "Stopping PostgreSQL..."
    pg_ctlcluster 15 main stop
    echo "PostgreSQL stopped"
}

# Function to check PostgreSQL status
status_postgres() {
    if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
        echo "PostgreSQL is running"
        return 0
    else
        echo "PostgreSQL is not running"
        return 1
    fi
}

# Function to restart PostgreSQL
restart_postgres() {
    stop_postgres
    sleep 2
    start_postgres
}

# Main script logic
case "$1" in
    start)
        start_postgres
        ;;
    stop)
        stop_postgres
        ;;
    status)
        status_postgres
        ;;
    restart)
        restart_postgres
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac 