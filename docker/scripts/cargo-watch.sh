#!/bin/bash

# Cargo Watch service control script for PortfolioDB development

set -e

SCRIPT_DIR="/opt/portfoliodb/scripts"
POSTGRES_SCRIPT="$SCRIPT_DIR/postgres.sh"
SRC_DIR="/opt/portfoliodb/src"

# Function to check if PostgreSQL is running
check_postgres() {
    if ! "$POSTGRES_SCRIPT" status >/dev/null 2>&1; then
        "$POSTGRES_SCRIPT" start
        sleep 2
    fi
}

# Function to start cargo watch
start_cargo_watch() {
    echo "=== Starting Cargo Watch for PortfolioDB Development ==="
    
    check_postgres

    cd "$SRC_DIR"
    exec su postgres -c "cargo watch \
        -w src \
        -w Cargo.toml \
        -w build.rs \
        -s \"cargo build --release && cargo run --release -- --database-url $DATABASE_URL\""
}

start_cargo_watch