#!/bin/bash

# Test script for PortfolioDB
# This script initializes a test database, runs tests, and cleans up

set -e

export DATABASE_URL="${DATABASE_URL:-postgres://test:test@localhost:5432/test}"
export RUST_BACKTRACE="${RUST_BACKTRACE:-0}"
export POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-/var/lib/postgresql/17/main}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_USER="${POSTGRES_USER:-test}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-test}"
export POSTGRES_DB="${POSTGRES_DB:-test}"

# Test file filtering
# TEST_FILES: Space-separated list of test file names (without .rs extension)
# Example: TEST_FILES="auth_tests user_tests"
TEST_FILES="${TEST_FILES:-}"
TEST_FILES_ARGS=""

build_test_args() {
    if [ -n "$TEST_FILES" ]; then
        echo "Running tests for specific files: $TEST_FILES"
        for file in $TEST_FILES; do
            TEST_FILES_ARGS="$TEST_FILES_ARGS --test $file"
        done
    else
        echo "Running all tests"
    fi
}

init_test_database() {
    export DB_ACTION=reset
    
    touch /var/log/postgresql/database-setup.log
    chown postgres:postgres /var/log/postgresql/database-setup.log
    
    if ! /opt/portfoliodb/scripts/init-db.sh > /var/log/postgresql/database-setup.log 2>&1; then
        echo "✗ Database initialization failed"
        exit 1
    fi
}

run_tests() {
    cd /opt/portfoliodb/src
    
    if psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
        echo "✓ Database connection successful"
    else
        echo "✗ Database connection failed"
        return 1
    fi
    
    if psql "$DATABASE_URL" -c "SELECT default_version, installed_version FROM pg_available_extensions WHERE name = 'timescaledb';" | grep -q "2."; then
        echo "✓ TimescaleDB extension is available"
    else
        echo "✗ TimescaleDB extension not found"
        return 1
    fi
    
    if [ -f "/opt/portfoliodb/src/Cargo.toml" ]; then
        echo "✓ Source code is mounted correctly"
    else
        echo "✗ Source code not found"
        return 1
    fi
    
    if cargo check --quiet; then
        echo "✓ Project builds successfully"
    else
        echo "✗ Project build failed"
        return 1
    fi
    
    build_test_args
    
    if cargo test $TEST_FILES_ARGS -- --nocapture ; then
        echo "All cargo tests passed ✓"
    else
        echo "cargo tests failed ✗"
        return 1
    fi
    
    echo "All tests passed! ✓"
}

cleanup_test_database() {
    export DB_ACTION=delete
    
    touch /var/log/postgresql/database-teardown.log
    chown postgres:postgres /var/log/postgresql/database-teardown.log
    
    if ! /opt/portfoliodb/scripts/init-db.sh > /var/log/postgresql/database-teardown.log 2>&1; then
        echo "✗ Database cleanup failed"
        exit 1
    fi
}

main() {
    init_test_database
    
    if run_tests; then
        exit_code=0
    else
        exit_code=1
    fi
    
    cleanup_test_database
    
    exit $exit_code
}

main "$@" 