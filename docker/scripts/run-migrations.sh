#!/bin/bash

# Database migration script for PortfolioDB
# This script should be run as the postgres user

set -e

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dev}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev}"
POSTGRES_DB="${POSTGRES_DB:-portfoliodb}"

DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "=== PortfolioDB Database Migrations ==="
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "======================================"

# Function to run all SQL migrations in the migrations directory
run_migrations() {
    echo "Applying SQL migrations..."
    MIGRATIONS_DIR="/opt/portfoliodb/src/migrations"
    if [ -d "$MIGRATIONS_DIR" ]; then
        for migration in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
            echo "Applying migration: $migration"
            psql "$DATABASE_URL" -f "$migration"
        done
    else
        echo "Migrations directory not found: $MIGRATIONS_DIR"
    fi
    echo "All migrations applied."
}

# Run migrations
run_migrations 