# PortfolioDB Docker Build System

# Load environment variables from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

export UID ?= $(shell id -u)
export GID ?= $(shell id -g)

export GIT_SUBMODULE_FLAGS ?=
export RUST_BACKTRACE ?= 0

export PROJECT_DIR ?= $(CURDIR)
export PORTFOLIODB_REPO_DIR = $(PROJECT_DIR)/external/portfoliodb
export PORTFOLIODB_BUILD_DIR = $(PORTFOLIODB_REPO_DIR)/target/release

export POSTGRES_DATA_DIR = $(PROJECT_DIR)/run/postgres/data
export POSTGRES_LOGS_DIR = $(PROJECT_DIR)/run/postgres/logs
export POSTGRES_ETC_DIR = $(PROJECT_DIR)/run/postgres/etc

export POSTGRES_TEST_LOGS_DIR = $(PROJECT_DIR)/run/test/logs/postgres

all: prod

help:
	@echo "Main Targets:"
	@echo "  all          - Build production and dev images (default)"
	@echo "  dev          - Build development Docker image"
	@echo "  portfoliodb  - Build PortfolioDB binary only"
	@echo ""
	@echo "Database Management:"
	@echo "  init-db      - Initialize dev database"
	@echo "  delete-db    - Delete dev database"
	@echo "  reset-db     - Reset dev database (delete-db then init-db)"
	@echo ""
	@echo "Testing:"
	@echo "  test         - Run all tests"
	@echo "  func-test    - Run functional tests (runs in a dedicated container)"
	@echo ""
	@echo "Development:"
	@echo "  run          - Start dev environment with hot reloading"
	@echo "  logs         - View dev container logs"
	@echo "  logs-watch   - Watch dev container logs in real-time"
	@echo "  stop         - Stop dev containers"
	@echo ""
	@echo "Cleaning:"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-containers - Clean Docker containers"
	@echo "  clean-images - Clean Docker images"
	@echo "  clean-all    - Clean everything"
	@echo ""
	@echo "Information:"
	@echo "  status       - Show build status"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make dev     - Build development image"
	@echo "  make init-db - Initialize database"
	@echo "  make run     - Start development environment"
	@echo "  make logs-watch - Watch container logs"
	@echo "  make stop - Stop all containers"
	@echo "  make clean-all - Clean everything"
	
# Ensure PostgreSQL data directory exists
$(POSTGRES_DATA_DIR):
	@echo "Creating PostgreSQL data directory: $(POSTGRES_DATA_DIR)"
	@mkdir -p $(POSTGRES_DATA_DIR)

# Ensure PostgreSQL logs directory exists
$(POSTGRES_LOGS_DIR):
	@echo "Creating PostgreSQL logs directory: $(POSTGRES_LOGS_DIR)"
	@mkdir -p $(POSTGRES_LOGS_DIR)

# Ensure PostgreSQL etc directory exists
$(POSTGRES_ETC_DIR):
	@echo "Creating PostgreSQL etc directory: $(POSTGRES_ETC_DIR)"
	@mkdir -p $(POSTGRES_ETC_DIR)

# Ensure PostgreSQL test logs directory exists
$(POSTGRES_TEST_LOGS_DIR):
	@echo "Creating PostgreSQL test logs directory: $(POSTGRES_TEST_LOGS_DIR)"
	@mkdir -p $(POSTGRES_TEST_LOGS_DIR)

# Initialize and update git submodule
$(PORTFOLIODB_REPO_DIR)/Cargo.toml:
	@echo "Initializing and updating PortfolioDB submodule..."
	git submodule update --init --recursive

$(PORTFOLIODB_BUILD_DIR)/portfoliodb: $(PORTFOLIODB_REPO_DIR)/Cargo.toml
	@echo "Building PortfolioDB binary..."
	(cd $(PORTFOLIODB_REPO_DIR) && cargo build --release)

portfoliodb: $(PORTFOLIODB_BUILD_DIR)/portfoliodb

# Build development Docker image
dev:
	@echo "Building development Docker image..."
	cd docker && docker build --target dev -t portfoliodb:dev .

# Initialize database (first run)
init-db: $(POSTGRES_DATA_DIR) $(POSTGRES_LOGS_DIR) $(POSTGRES_ETC_DIR)
	cd docker && DB_ACTION=init docker-compose up portfoliodb-init

# Delete database data (clean slate)
delete-db: $(POSTGRES_DATA_DIR) $(POSTGRES_LOGS_DIR) $(POSTGRES_ETC_DIR)
	cd docker && DB_ACTION=delete docker-compose up portfoliodb-init

# Reset database (delete and rebuild from scratch)
reset-db: $(POSTGRES_DATA_DIR) $(POSTGRES_LOGS_DIR) $(POSTGRES_ETC_DIR)
	cd docker && DB_ACTION=reset docker-compose up portfoliodb-init

# Run functional tests
func-test: $(POSTGRES_TEST_LOGS_DIR)
	@echo "Running PortfolioDB functional tests..."
	@cd docker && TEST_FILES="staging" docker-compose up portfoliodb-test

# Run tests (alias for func-test)
test: func-test

# Run development environment
run: docker $(POSTGRES_DATA_DIR) $(POSTGRES_LOGS_DIR) $(POSTGRES_ETC_DIR)
	@echo "Starting development environment with cargo-watch..."
	cd docker && docker-compose up portfoliodb-dev
	@echo "Development container started with hot reloading enabled."
	@echo "Source code changes will automatically trigger rebuilds and restarts."
	@echo "Run 'make logs' to view the container logs."

logs:
	cd docker && docker-compose logs --tail=100

logs-watch:
	cd docker && docker-compose logs -f

stop:
	@echo "Stopping containers..."
	cd docker && docker-compose down

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(PORTFOLIODB_BUILD_DIR)

clean-containers:
	@echo "Cleaning Docker containers..."
	cd docker && docker-compose down --volumes --remove-orphans
	docker rm -f portfoliodb-init || true
	docker rm -f portfoliodb-dev || true
	docker rm -f portfoliodb-test || true

clean-images:
	@echo "Cleaning Docker images..."
	cd docker && docker-compose down --rmi local
	docker rmi portfoliodb:dev portfoliodb:prod || true
	docker rmi docker-portfoliodb-init:latest || true
	docker rmi docker-portfoliodb-test:latest || true

clean-submodules:
	@echo "Cleaning submodule build artifacts..."
	cd external/portfoliodb && cargo clean

clean-run:
	@echo "Cleaning run directory..."
	rm -rf $(POSTGRES_DATA_DIR)/*
	rm -rf $(POSTGRES_LOGS_DIR)/*
	rm -rf $(POSTGRES_ETC_DIR)/*
	rm -rf $(POSTGRES_TEST_LOGS_DIR)/*

clean-all: clean clean-containers clean-images clean-submodules

status:
	@echo "=== PortfolioDB Build Status ==="
	@echo "Production binary exists: $$([ -f $(PORTFOLIODB_BUILD_DIR)/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "Submodule initialized: $$([ -d external/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "PostgreSQL data directory exists: $$([ -d $(POSTGRES_DATA_DIR) ] && echo "Yes" || echo "No")"
	@echo "PostgreSQL logs directory exists: $$([ -d $(POSTGRES_LOGS_DIR) ] && echo "Yes" || echo "No")"
	@echo "PostgreSQL etc directory exists: $$([ -d $(POSTGRES_ETC_DIR) ] && echo "Yes" || echo "No")"
	@echo "Submodule status:"
	@git submodule status 2>/dev/null || echo "No submodules configured"
	@echo "Docker Compose services:"
	@cd docker && docker-compose ps

.PHONY: all help dev init-db delete-db reset-db test func-test run logs logs-watch watch restart stop clean clean-containers clean-images clean-submodules clean-all status clean-run