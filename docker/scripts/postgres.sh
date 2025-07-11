#!/bin/bash

# PostgreSQL service script for PortfolioDB
# Usage: postgres.sh {start|stop|status|restart}

POSTGRES_DATA_DIR="/var/lib/postgresql/data"
POSTGRES_LOG_DIR="/var/log/postgresql"
POSTGRES_CLUSTER="17 main"

# Function to start PostgreSQL
start_postgres() {
    echo "Starting PostgreSQL..."
    
    # Create log directory if it doesn't exist
    mkdir -p "$POSTGRES_LOG_DIR"
    
    # Start PostgreSQL cluster
    pg_ctlcluster 17 main start
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h localhost -p 5432; do
        echo "Waiting for PostgreSQL..."
        sleep 1
    done
    
    echo "PostgreSQL started successfully"
}

# Function to stop PostgreSQL
stop_postgres() {
    echo "Stopping PostgreSQL..."
    pg_ctlcluster 17 main stop
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