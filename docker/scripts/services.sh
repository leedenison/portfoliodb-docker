#!/bin/bash

# Main startup script for PortfolioDB container
# Starts PostgreSQL first, then PortfolioDB application

set -e

SCRIPT_DIR="/opt/portfoliodb/scripts"
POSTGRES_SCRIPT="$SCRIPT_DIR/postgres.sh"
PORTFOLIODB_SCRIPT="$SCRIPT_DIR/portfoliodb.sh"

# Function to check if a script exists and is executable
check_script() {
    local script="$1"
    local name="$2"
    
    if [ ! -f "$script" ]; then
        echo "Error: $name script not found at $script"
        exit 1
    fi
    
    if [ ! -x "$script" ]; then
        echo "Error: $name script is not executable"
        exit 1
    fi
}

# Function to start all services
start_services() {
    echo "=== Starting PortfolioDB Services ==="
    
    # Check scripts exist
    check_script "$POSTGRES_SCRIPT" "PostgreSQL"
    check_script "$PORTFOLIODB_SCRIPT" "PortfolioDB"
    
    # Start PostgreSQL first
    "$POSTGRES_SCRIPT" start
    
    # Wait a moment for PostgreSQL to fully initialize
    sleep 2
    
    # Check PostgreSQL is running
    if ! "$POSTGRES_SCRIPT" status >/dev/null 2>&1; then
        echo "Error: PostgreSQL failed to start"
        exit 1
    fi
    
    echo "PostgreSQL is ready"
    
    # Start PortfolioDB application
    "$PORTFOLIODB_SCRIPT" start
}

# Function to stop all services
stop_services() {
    echo "=== Stopping PortfolioDB Services ==="
    
    # Stop PortfolioDB first (if running)
    if [ -f "$PORTFOLIODB_SCRIPT" ]; then
        "$PORTFOLIODB_SCRIPT" stop || true
    fi
    
    # Stop PostgreSQL
    if [ -f "$POSTGRES_SCRIPT" ]; then
        "$POSTGRES_SCRIPT" stop || true
    fi
}

# Function to check status of all services
status_services() {
    echo "=== PortfolioDB Services Status ==="
    
    echo "PostgreSQL:"
    if [ -f "$POSTGRES_SCRIPT" ]; then
        "$POSTGRES_SCRIPT" status || echo "  Not running"
    else
        echo "  Script not found"
    fi
    
    echo "PortfolioDB:"
    if [ -f "$PORTFOLIODB_SCRIPT" ]; then
        "$PORTFOLIODB_SCRIPT" status || echo "  Not running"
    else
        echo "  Script not found"
    fi
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        status_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo ""
        echo "This script manages both PostgreSQL and PortfolioDB services."
        echo "Services are started in the correct order: PostgreSQL first, then PortfolioDB."
        exit 1
        ;;
esac 