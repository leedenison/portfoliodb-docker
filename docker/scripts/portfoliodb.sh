#!/bin/bash

# PortfolioDB application service script
# Usage: portfoliodb.sh {start|stop|status|restart}

APP_BINARY="/opt/portfoliodb/portfoliodb"
APP_NAME="PortfolioDB"

# Function to start PortfolioDB
start_portfoliodb() {
    echo "Starting $APP_NAME..."
    
    # Check if binary exists
    if [ ! -f "$APP_BINARY" ]; then
        echo "Error: $APP_NAME binary not found at $APP_BINARY"
        echo "Waiting for binary to be mounted..."
        while [ ! -f "$APP_BINARY" ]; do
            sleep 1
        done
        echo "Binary found, starting $APP_NAME..."
    fi
    
    # Check if binary is executable
    if [ ! -x "$APP_BINARY" ]; then
        echo "Error: $APP_NAME binary is not executable"
        exit 1
    fi
    
    # Check if DATABASE_URL is set
    if [ -z "$DATABASE_URL" ]; then
        echo "Error: DATABASE_URL environment variable is not set"
        exit 1
    fi
    
    # Start the application with database URL
    echo "Starting $APP_NAME in $(if [ "$ENVIRONMENT" = "prod" ]; then echo "production"; else echo "development"; fi) mode..."
    echo "Using database URL: $DATABASE_URL"
    exec "$APP_BINARY" --database-url "$DATABASE_URL"
}

# Function to stop PortfolioDB
stop_portfoliodb() {
    echo "Stopping $APP_NAME..."
    # Since we use exec, the process will be terminated when the container stops
    # This function is mainly for consistency with service script patterns
    echo "$APP_NAME stopped"
}

# Function to check PortfolioDB status
status_portfoliodb() {
    if [ -f "$APP_BINARY" ]; then
        echo "$APP_NAME binary is available"
        if [ -x "$APP_BINARY" ]; then
            echo "$APP_NAME binary is executable"
            return 0
        else
            echo "$APP_NAME binary is not executable"
            return 1
        fi
    else
        echo "$APP_NAME binary is not available"
        return 1
    fi
}

# Function to restart PortfolioDB
restart_portfoliodb() {
    stop_portfoliodb
    sleep 1
    start_portfoliodb
}

# Main script logic
case "$1" in
    start)
        start_portfoliodb
        ;;
    stop)
        stop_portfoliodb
        ;;
    status)
        status_portfoliodb
        ;;
    restart)
        restart_portfoliodb
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac 