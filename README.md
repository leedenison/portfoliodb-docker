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
   ```

2. **Run the development service:**
   ```bash
   make run
   ```

## Available Commands

### Build Commands
- `make all` - Build all Docker images
- `make dev` - Build development Docker image
- `make prod` - Build production Docker image

### Database Commands
- `make init-db` - Initialize database
- `make delete-db` - Delete database data
- `make reset-db` - Run delete-db followed by init-db

### Docker Commands
- `make run` - Start development container with hot reloading (requires existing database)
- `make stop` - Stop development container
- `make logs` - View logs from development container
- `make logs-watch` - View logs with continuous monitoring

### Utility Commands
- `make clean` - Clean build artifacts
- `make clean-all` - Clean all artifacts (does not delete the database)
- `make status` - Show current build status

## Development Workflow

1. **Initialize database:**
   ```bash
   make init-db
   ```

2. **Start development environment:**
   ```bash
   make run
   ```
   This starts the development container with hot reloading enabled. Source code changes will automatically trigger rebuilds and restarts.  Check progress with `make logs`


   The development environment uses cargo-watch to automatically:
   - Watch for source code changes
   - Rebuild the project when changes are detected
   - Restart the gRPC server automatically
   - No manual restarts required

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
