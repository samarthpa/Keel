.PHONY: help install dev test lint format clean docker-build docker-run docker-stop up down fmt

# Default target
help:
	@echo "Available commands:"
	@echo "  install     - Install dependencies"
	@echo "  dev         - Run development server with hot reload"
	@echo "  up          - Start Docker Compose services"
	@echo "  down        - Stop Docker Compose services"
	@echo "  fmt         - Format code with ruff and black"
	@echo "  test        - Run tests"
	@echo "  lint        - Run linting"
	@echo "  clean       - Clean up generated files"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run  - Run with Docker Compose"
	@echo "  docker-stop - Stop Docker Compose"

# Install dependencies
install:
	pip install -r requirements.txt

# Run development server with hot reload
dev:
	uvicorn app.main:app --reload --port 8000

# Start Docker Compose services
up:
	docker-compose up -d

# Stop Docker Compose services
down:
	docker-compose down

# Format code with ruff and black
fmt:
	pip install ruff black
	ruff check --fix --unsafe-fixes app/ || true
	black app/

# Run tests
test:
	pytest tests/ -v --cov=app

# Run linting
lint:
	flake8 app/ tests/
	mypy app/

# Format code (legacy - use fmt instead)
format:
	black app/ tests/
	isort app/ tests/

# Clean up generated files
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache/
	rm -rf .mypy_cache/

# Build Docker image
docker-build:
	docker build -t keel-api .

# Run with Docker Compose (legacy - use up instead)
docker-run:
	docker-compose up -d

# Stop Docker Compose (legacy - use down instead)
docker-stop:
	docker-compose down

# Database migrations
migrate:
	alembic upgrade head

# Create new migration
migrate-create:
	alembic revision --autogenerate -m "$(message)"

# Database setup
db-setup:
	alembic upgrade head

# Health check
health:
	curl http://localhost:8000/health/

# API documentation
docs:
	mkdocs serve
