# PortfolioDB Docker Development Environment

This project provides a Docker-based development environment for PortfolioDB with PostgreSQL and TimescaleDB integration.

## Prerequisites

- Docker
- Docker Compose
- Make
- Git

## Quick Start

1. **First-time setup:**
   ```bash
   make init-db
   make run
   ```

2. **Subsequent runs:**
   ```bash
   make run
   ```

## Available Commands

### Build Commands
- `make all` - Build PortfolioDB binary and production Docker image
- `make portfoliodb` - Clone repo and build binary only
- `make docker` - Build development Docker image
- `make prod` - Build production Docker image

### Development Commands
- `make run` - Start development environment (requires existing database)
- `make init-db` - Initialize database only (first run)
- `make delete-db` - Delete database data (clean slate)
- `make reset-db` - Reset database (delete and rebuild from scratch)
- `make stop` - Stop development service
- `make status` - Show current build status
- `make logs` - View logs from development service
- `make watch` - Watch for changes in PortfolioDB repo and auto-rebuild

### Utility Commands
- `make clean` - Clean build artifacts
- `make clean-all` - Clean everything including Docker images

## Development Workflow

### First Time Setup

1. **Initialize database:**
   ```bash
   make init-db
   ```
   This will:
   - Create the PostgreSQL data directory (`/tmp/portfoliodb/data`)
   - Initialize a fresh PostgreSQL cluster with TimescaleDB
   - Create the database and user

2. **Start development environment:**
   ```bash
   make run
   ```
   This starts the development container with the initialized database.

### Regular Development

1. **Start the development environment:**
   ```bash
   make run
   ```
   This starts the container with the existing database.

2. **View logs (optional):**
   ```bash
   make logs
   ```

3. **Watch for changes (optional):**
   ```bash
   make watch
   ```
   The binary will be automatically rebuilt and the service restarted when changes are detected.

### Database Management

- **Initialize database (first run or reinitialize):**
  ```bash
  make init-db
  ```

- **Delete database data (clean slate, no reinitialization):**
  ```bash
  make delete-db
  ```

- **Reset database (delete everything and start fresh):**
  ```bash
  make reset-db
  ```

## Ports

- **PortfolioDB gRPC**: localhost:50001
- **PostgreSQL**: localhost:5432

## Database Configuration

The application uses PostgreSQL 17 with TimescaleDB extensions:

- **Database**: `portfoliodb`
- **Username**: `portfoliodb`
- **Password**: `portfoliodb_dev_password`
- **Connection String**: `postgres://portfoliodb:portfoliodb_dev_password@localhost:5432/portfoliodb`
- **TimescaleDB**: Automatically installed and configured

### Connecting to the Database

```bash
# Connect from host machine
psql -h localhost -p 5432 -U portfoliodb -d portfoliodb

# Or connect from inside the container
docker exec -it portfoliodb-dev psql -U portfoliodb -d portfoliodb
```