.PHONY: help setup install start stop restart logs console db-create db-migrate db-seed db-reset test clean build up down shell db-console rubocop format docker-build docker-up docker-down docker-logs docker-console docker-shell

# Default target
.DEFAULT_GOAL := help

## Help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Local Development (without Docker)
setup: ## Initial setup - install dependencies and setup database
	bundle install
	rails db:create db:migrate db:seed

install: ## Install dependencies
	bundle install

start: ## Start the Rails server locally
	bin/dev

stop: ## Stop the Rails server (use Ctrl+C)
	@echo "Press Ctrl+C to stop the server"

console: ## Open Rails console
	rails console

db-create: ## Create database
	rails db:create

db-migrate: ## Run database migrations
	rails db:migrate

db-seed: ## Seed the database
	rails db:seed

db-reset: ## Reset database (drop, create, migrate, seed)
	rails db:drop db:create db:migrate db:seed

db-console: ## Open database console
	rails dbconsole

test: ## Run tests
	rails test

rubocop: ## Run RuboCop linter
	bundle exec rubocop

format: ## Auto-fix RuboCop violations
	bundle exec rubocop -A

clean: ## Clean temporary files
	rm -rf tmp/cache
	rm -rf log/*.log
	rm -rf tmp/pids

## Docker Development
docker-build: ## Build Docker images
	docker-compose build

docker-up: ## Start application with Docker
	docker-compose up -d
	@echo "Application is starting..."
	@echo "Web: http://localhost:3000"
	@echo "Database: localhost:5432"

docker-down: ## Stop Docker containers
	docker-compose down

docker-restart: ## Restart Docker containers
	docker-compose restart

docker-logs: ## Show Docker logs (use Ctrl+C to exit)
	docker-compose logs -f

docker-console: ## Open Rails console in Docker
	docker-compose exec web rails console

docker-shell: ## Open shell in web container
	docker-compose exec web bash

docker-db-create: ## Create database in Docker
	docker-compose exec web rails db:create

docker-db-migrate: ## Run migrations in Docker
	docker-compose exec web rails db:migrate

docker-db-seed: ## Seed database in Docker
	docker-compose exec web rails db:seed

docker-db-reset: ## Reset database in Docker
	docker-compose exec web rails db:drop db:create db:migrate db:seed

docker-clean: ## Remove all Docker containers and volumes
	docker-compose down -v
	docker system prune -f

## Aliases
up: docker-up ## Alias for docker-up
down: docker-down ## Alias for docker-down
logs: docker-logs ## Alias for docker-logs
shell: docker-shell ## Alias for docker-shell
build: docker-build ## Alias for docker-build
