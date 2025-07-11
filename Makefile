# PortfolioDB Docker Build System

# Load environment variables from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

GIT_SUBMODULE_FLAGS ?=
BUILD_DIR = docker/bin
DOCKER_IMAGE_NAME = portfoliodb

all: portfoliodb prod

# Initialize and update git submodule
external/portfoliodb/Cargo.toml:
	@echo "Initializing and updating PortfolioDB submodule..."
	git $(GIT_SUBMODULE_FLAGS) submodule update --init --recursive

$(BUILD_DIR)/portfoliodb: external/portfoliodb/Cargo.toml
	@echo "Building PortfolioDB binary..."
	@mkdir -p $(BUILD_DIR)
	(cd external/portfoliodb && make all) && cp external/portfoliodb/target/release/portfoliodb $(BUILD_DIR)/portfoliodb

portfoliodb: $(BUILD_DIR)/portfoliodb

# Build development Docker image
docker:
	@echo "Building development Docker image..."
	cd docker && docker build --target dev -t $(DOCKER_IMAGE_NAME):dev .

# Build production Docker image
prod: portfoliodb
	@echo "Building production Docker image..."
	cd docker && docker build --target prod -t $(DOCKER_IMAGE_NAME):prod .

run: portfoliodb docker
	@echo "Starting development environment..."
	cd docker && docker-compose up -d
	@echo "Development container started. Binary will be auto-reloaded on changes."
	@echo "Run 'make logs' to view the container logs."

logs:
	cd docker && docker-compose logs -f

watch: external/portfoliodb/Cargo.toml
	@echo "Watching for changes in PortfolioDB repository..."
	cd external/portfoliodb && cargo watch -x 'make all' -x 'cp target/release/portfoliodb ../../$(BUILD_DIR)/portfoliodb'

stop:
	@echo "Stopping containers..."
	cd docker && docker-compose down

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

clean-all: clean
	@echo "Cleaning Docker images..."
	cd docker && docker-compose down --rmi local --volumes --remove-orphans
	docker rmi $(DOCKER_IMAGE_NAME):dev $(DOCKER_IMAGE_NAME):prod 2>/dev/null || true
	@echo "Cleaning submodule..."
	git $(GIT_SUBMODULE_FLAGS) submodule deinit -f external/portfoliodb 2>/dev/null || true
	rm -rf external/portfoliodb

status:
	@echo "=== PortfolioDB Build Status ==="
	@echo "Binary exists: $$([ -f $(BUILD_DIR)/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "Submodule initialized: $$([ -d external/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "Submodule status:"
	@git submodule status 2>/dev/null || echo "No submodules configured"
	@echo "Docker Compose services:"
	@cd docker && docker-compose ps

.PHONY: all portfoliodb docker prod run logs watch restart stop clean clean-all status