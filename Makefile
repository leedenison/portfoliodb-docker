# PortfolioDB Docker Build System
PORTFOLIODB_URL = https://github.com/leedenison/portfoliodb.git
PORTFOLIODB_DIR = external/portfoliodb
BUILD_DIR = docker/bin
DOCKER_IMAGE_NAME = portfoliodb

# Top-level build targets
all: portfoliodb prod

# Clone PortfolioDB repo
$(PORTFOLIODB_DIR):
	@echo "Cloning PortfolioDB repository..."
	git clone $(PORTFOLIODB_URL) $(PORTFOLIODB_DIR)

# Build PortfolioDB binary
$(BUILD_DIR)/portfoliodb: $(PORTFOLIODB_DIR)
	@echo "Building PortfolioDB binary..."
	@mkdir -p $(BUILD_DIR)
	(cd $(PORTFOLIODB_DIR) && make all) && cp $(PORTFOLIODB_DIR)/build/portfoliodb $(BUILD_DIR)/portfoliodb

# Alias for building the binary
portfoliodb: $(BUILD_DIR)/portfoliodb

# Build development Docker image
docker:
	@echo "Building development Docker image..."
	cd docker && docker build --target dev -t $(DOCKER_IMAGE_NAME):dev .

# Build production Docker image
prod: portfoliodb
	@echo "Building production Docker image..."
	cd docker && docker build --target prod -t $(DOCKER_IMAGE_NAME):prod .

# Development stage - run with docker-compose
run: portfoliodb docker
	@echo "Starting development environment..."
	cd docker && docker-compose up -d
	@echo "Development container started. Binary will be auto-reloaded on changes."
	@echo "Run 'make logs' to view the container logs."

# View logs
logs:
	cd docker && docker-compose logs -f

# Watch for changes in PortfolioDB repo and rebuild
watch:
	@echo "Watching for changes in PortfolioDB repository..."
	cd $(PORTFOLIODB_DIR) && cargo watch -x 'make all' -x 'cp target/release/portfoliodb ../../$(BUILD_DIR)/portfoliodb'

# Stop containers
stop:
	@echo "Stopping containers..."
	cd docker && docker-compose down

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf $(PORTFOLIODB_DIR)

# Clean everything including Docker images
clean-all: clean
	@echo "Cleaning Docker images..."
	cd docker && docker-compose down --rmi local --volumes --remove-orphans
	docker rmi $(DOCKER_IMAGE_NAME):dev $(DOCKER_IMAGE_NAME):prod 2>/dev/null || true

# Show status
status:
	@echo "=== PortfolioDB Build Status ==="
	@echo "Binary exists: $$([ -f $(BUILD_DIR)/portfoliodb ] && echo "Yes" || echo "No")"
	@echo "Repo cloned: $$([ -d $(PORTFOLIODB_DIR) ] && echo "Yes" || echo "No")"
	@echo "Docker Compose services:"
	@cd docker && docker-compose ps

.PHONY: all portfoliodb docker prod run logs watch restart stop clean clean-all status