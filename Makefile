# PortfolioDB Docker Build System

# Load environment variables from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

GIT_SUBMODULE_FLAGS ?=
BUILD_DIR = docker/bin
POSTGRES_DATA_DIR = /tmp/portfoliodb/data
POSTGRES_LOGS_DIR = /tmp/portfoliodb/logs/postgresql

all: prod

# Ensure PostgreSQL data directory exists
$(POSTGRES_DATA_DIR):
	@echo "Creating PostgreSQL data directory: $(POSTGRES_DATA_DIR)"
	@mkdir -p $(POSTGRES_DATA_DIR)

# Ensure PostgreSQL logs directory exists
$(POSTGRES_LOGS_DIR):
	@echo "Creating PostgreSQL logs directory: $(POSTGRES_LOGS_DIR)"
	@mkdir -p $(POSTGRES_LOGS_DIR)

# Initialize and update git submodule
external/portfoliodb/Cargo.toml:
	@echo "Initializing and updating PortfolioDB submodule..."
	git $(GIT_SUBMODULE_FLAGS) submodule update --init --recursive

$(BUILD_DIR)/portfoliodb: external/portfoliodb/Cargo.toml
	@echo "Building PortfolioDB binary..."
	@mkdir -p $(BUILD_DIR)
	(cd external/portfoliodb && cargo build --release) && cp external/portfoliodb/target/release/portfoliodb $(BUILD_DIR)/portfoliodb

portfoliodb: $(BUILD_DIR)/portfoliodb

# Build development Docker image
dev:
	@echo "Building development Docker image..."
	cd docker && docker build --target dev -t portfoliodb:dev .

# Build production Docker image
prod: $(BUILD_DIR)/portfoliodb
	@echo "Building production Docker image..."
	cd docker && docker build --target prod -t portfoliodb:prod .

# Initialize database (first run)
init-db: $(POSTGRES_DATA_DIR)
	cd docker && docker-compose --profile init up portfoliodb-init

# Delete database data (clean slate)
delete-db: $(POSTGRES_DATA_DIR)
	cd docker && DB_ACTION=delete docker-compose --profile init up portfoliodb-init

# Reset database (delete and rebuild from scratch)
reset-db: $(POSTGRES_DATA_DIR)
	cd docker && DB_ACTION=reset docker-compose --profile init up portfoliodb-init

# Run tests
test:
	@echo "Running PortfolioDB tests..."
	@cd docker && docker-compose --profile test up portfoliodb-test

# Run development environment
run: docker $(POSTGRES_DATA_DIR) $(POSTGRES_LOGS_DIR)
	@echo "Starting development environment with cargo-watch..."
	cd docker && docker-compose up -d
	@echo "Development container started with hot reloading enabled."
	@echo "Source code changes will automatically trigger rebuilds and restarts."
	@echo "Run 'make logs' to view the container logs."

logs:
	cd docker && docker-compose logs --tail=20

logs-watch:
	cd docker && docker-compose logs -f

stop:
	@echo "Stopping containers..."
	cd docker && docker-compose down

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

clean-containers:
	@echo "Cleaning Docker containers..."
	cd docker && docker-compose down --volumes --remove-orphans
	docker rm -f portfoliodb-init 2>/dev/null || true
	docker rm -f portfoliodb-dev 2>/dev/null || true
	docker rm -f portfoliodb-test 2>/dev/null || true

clean-images:
	@echo "Cleaning Docker images..."
	cd docker && docker-compose down --rmi local
	docker rmi portfoliodb:dev portfoliodb:prod 2>/dev/null || true
	docker rmi docker-portfoliodb-init:latest 2>/dev/null || true
	docker rmi docker-portfoliodb-test:latest 2>/dev/null || true

clean-submodules:
	@echo "Cleaning submodule build artifacts..."
	cd external/portfoliodb && make clean 2>/dev/null || true

clean-all: clean clean-containers clean-images clean-submodules

status:
	@echo "=== PortfolioDB Build Status ==="
	@echo "Production binary exists: $$([ -f $(BUILD_DIR)/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "Submodule initialized: $$([ -d external/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "PostgreSQL data directory exists: $$([ -d $(POSTGRES_DATA_DIR) ] && echo "Yes" || echo "No")"
	@echo "PostgreSQL logs directory exists: $$([ -d $(POSTGRES_LOGS_DIR) ] && echo "Yes" || echo "No")"
	@echo "Submodule status:"
	@git submodule status 2>/dev/null || echo "No submodules configured"
	@echo "Docker Compose services:"
	@cd docker && docker-compose ps

.PHONY: all dev prod init-db delete-db reset-db test run logs logs-watch watch restart stop clean clean-containers clean-images clean-submodules clean-all status