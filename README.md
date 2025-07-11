# PortfolioDB Docker Build System

This project manages the build and deployment of the PortfolioDB application using Docker with multi-stage builds.

## Prerequisites

- Docker
- Docker Compose
- Make
- Git

## Quick Start

1. **Build everything:**
   ```bash
   make all
   ```

2. **Start development environment:**
   ```bash
   make dev
   ```

## Available Commands

### Build Commands
- `make all` - Build PortfolioDB binary and production Docker image
- `make portfoliodb` - Clone repo and build binary only
- `make docker` - Build development Docker image
- `make prod` - Build production Docker image

### Development Commands
- `make run` - Start development container with volume mounts
- `make stop` - Stop development service
- `make status` - Show current build status
- `make logs` - View logs from development service
- `make watch` - Watch for changes in PortfolioDB repo and auto-rebuild

### Utility Commands
- `make clean` - Clean build artifacts
- `make clean-all` - Clean everything including Docker images

## Development Workflow

1. Start the development environment:
   ```bash
   make run
   ```
   This will automatically build the PortfolioDB binary if needed before starting the container.

2. View logs (optional):
   ```bash
   make logs
   ```

3. In another terminal, watch for changes:
   ```bash
   make watch
   ```

4. The binary will be automatically rebuilt and the service restarted when changes are detected.

## Ports

- **Development**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Database Configuration

The application uses PostgreSQL with TimescaleDB extensions for time-series data:

- **Database**: `portfoliodb`
- **Username**: `portfoliodb`
- **Password**: `portfoliodb_dev_password` (dev) / `portfoliodb_prod_password` (prod)
- **Configuration**: Available at `/opt/portfoliodb/etc/postgresql.json` inside the container
- **TimescaleDB**: Automatically installed and enabled

### Connecting to the Database

```bash
# Connect from host machine
psql -h localhost -p 5432 -U portfoliodb -d portfoliodb

# Or connect from inside the container
docker exec -it portfoliodb-dev psql -U portfoliodb -d portfoliodb
``` 