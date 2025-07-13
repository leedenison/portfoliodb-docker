#!/bin/bash

# Test script for PortfolioDB
# This script initializes a test database, runs tests, and cleans up

set -e  # Exit on any error

# Environment variables
POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-/var/lib/postgresql/17/main}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-portfoliodb}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-portfoliodb_test_password}"
POSTGRES_DB="${POSTGRES_DB:-portfoliodb_test}"
DATABASE_URL="${DATABASE_URL:-postgres://portfoliodb:portfoliodb_test_password@localhost:5432/portfoliodb_test}"

echo "=== PortfolioDB Test Suite ==="
echo "Test database: $POSTGRES_DB"
echo "Database URL: $DATABASE_URL"
echo "Data directory: $POSTGRES_DATA_DIR"
echo "================================"

# Function to initialize test database
init_test_database() {
    echo "Initializing test database..."
    
    # Set DB_ACTION to init for the init-db.sh script
    export DB_ACTION=init
    
    # Run the database initialization script
    /opt/portfoliodb/scripts/init-db.sh
    
    echo "Test database initialized successfully"
}

# Function to run tests
run_tests() {
    echo "Running tests..."
    
    # Change to the source directory
    cd /opt/portfoliodb/src
    
    # Run a simple "Hello World" test to verify the setup works
    echo "Running Hello World test..."
    
    # Test 1: Check if we can connect to the database
    echo "Test 1: Database connection test"
    if psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
        echo "✓ Database connection successful"
    else
        echo "✗ Database connection failed"
        return 1
    fi
    
    # Test 2: Check if TimescaleDB extension is available
    echo "Test 2: TimescaleDB extension test"
    if psql "$DATABASE_URL" -c "SELECT default_version, installed_version FROM pg_available_extensions WHERE name = 'timescaledb';" | grep -q "2.21.0"; then
        echo "✓ TimescaleDB extension is available"
    else
        echo "✗ TimescaleDB extension not found"
        return 1
    fi
    
    # Test 3: Check if source code is mounted correctly
    echo "Test 3: Source code mount test"
    if [ -f "/opt/portfoliodb/src/Cargo.toml" ]; then
        echo "✓ Source code is mounted correctly"
    else
        echo "✗ Source code not found"
        return 1
    fi
    
    # Test 4: Check if we can build the project
    echo "Test 4: Build test"
    if cargo check --quiet; then
        echo "✓ Project builds successfully"
    else
        echo "✗ Project build failed"
        return 1
    fi
    
    echo "All tests passed! ✓"
}

# Function to clean up test database
cleanup_test_database() {
    echo "Cleaning up test database..."
    
    # Set DB_ACTION to delete for the init-db.sh script
    export DB_ACTION=delete
    
    # Run the database cleanup script
    /opt/portfoliodb/scripts/init-db.sh
    
    echo "Test database cleaned up successfully"
}

# Main test workflow
main() {
    echo "Starting PortfolioDB test suite..."
    
    # Initialize the test database
    init_test_database
    
    # Run the tests
    if run_tests; then
        echo "Test suite completed successfully"
        exit_code=0
    else
        echo "Test suite failed"
        exit_code=1
    fi
    
    # Clean up the test database
    cleanup_test_database
    
    echo "Test suite finished with exit code: $exit_code"
    exit $exit_code
}

# Run main function
main "$@" 