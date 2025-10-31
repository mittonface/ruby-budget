# Ruby Budget

A modern Ruby on Rails application built with Rails 8.1, PostgreSQL, and modern frontend tooling.

## Features

- **Rails 8.1** - Latest version with all modern features
- **PostgreSQL** - Robust and reliable database
- **Tailwind CSS** - Utility-first CSS framework
- **Hotwire** - Turbo and Stimulus for modern, reactive interfaces
- **Importmap** - Import maps for JavaScript modules
- **Solid Queue** - Database-backed Active Job backend
- **Solid Cache** - Database-backed Rails cache
- **Docker** - Production-ready containerization
- **Kamal** - Modern deployment tooling

## Prerequisites

### For Local Development
- Ruby 3.3.6 (see `.ruby-version`)
- PostgreSQL 14+
- Node.js 18+ (for Tailwind CSS compilation)

### For Docker Development
- Docker 20.10+
- Docker Compose 2.0+

## Getting Started

### Option 1: Local Development (without Docker)

1. **Install dependencies**
   ```bash
   bundle install
   ```

2. **Setup database**

   Make sure PostgreSQL is running, then:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

   Or use the Makefile:
   ```bash
   make setup
   ```

3. **Start the development server**
   ```bash
   bin/dev
   ```

   This starts both the Rails server and Tailwind CSS watcher using Foreman.

   The application will be available at http://localhost:3000

### Option 2: Docker Development (Recommended)

1. **Build and start containers**
   ```bash
   make docker-up
   ```

   Or manually:
   ```bash
   docker-compose up -d
   ```

2. **Setup database**
   ```bash
   make docker-db-create
   make docker-db-migrate
   make docker-db-seed
   ```

   Or in one command:
   ```bash
   docker-compose exec web rails db:setup
   ```

3. **Access the application**

   The application will be available at http://localhost:3000

## Makefile Commands

The project includes a comprehensive Makefile with helpful commands:

### Local Development
```bash
make help            # Show all available commands
make setup           # Initial setup (install deps, setup DB)
make install         # Install dependencies
make start           # Start Rails server
make console         # Open Rails console
make db-migrate      # Run migrations
make db-seed         # Seed database
make db-reset        # Reset database
make test            # Run tests
make rubocop         # Run linter
make format          # Auto-fix linting issues
make clean           # Clean temporary files
```

### Docker Development
```bash
make docker-build    # Build Docker images
make docker-up       # Start containers (or just: make up)
make docker-down     # Stop containers (or just: make down)
make docker-logs     # View logs (or just: make logs)
make docker-console  # Open Rails console in Docker
make docker-shell    # Open shell in container (or just: make shell)
make docker-db-migrate   # Run migrations in Docker
make docker-db-reset     # Reset database in Docker
make docker-clean    # Remove containers and volumes
```

## Project Structure

```
.
├── app/                    # Application code
│   ├── assets/            # CSS, images
│   ├── controllers/       # Controllers
│   ├── javascript/        # Stimulus controllers
│   ├── models/            # Models
│   └── views/             # Views
├── bin/                   # Executable scripts
├── config/                # Configuration
│   ├── database.yml       # Database config
│   ├── routes.rb          # Routes
│   └── environments/      # Environment configs
├── db/                    # Database files
│   ├── migrate/           # Migrations
│   └── seeds.rb           # Seed data
├── lib/                   # Library code
├── public/                # Static files
├── test/                  # Tests
├── Dockerfile             # Production Docker image
├── docker-compose.yml     # Docker development setup
├── Makefile               # Common commands
└── Procfile.dev           # Development processes
```

## Configuration

### Environment Variables

Create a `.env` file for local development (not needed for Docker):

```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ruby_budget_development
RAILS_MASTER_KEY=<your-master-key>  # Found in config/master.key
```

### Database Configuration

Database settings are in `config/database.yml`. For Docker, the connection is configured via the `DATABASE_URL` environment variable in `docker-compose.yml`.

## Development Workflow

### Adding a Migration
```bash
# Local
rails generate migration AddColumnToTable column:type
rails db:migrate

# Docker
docker-compose exec web rails generate migration AddColumnToTable column:type
make docker-db-migrate
```

### Generating a Controller
```bash
# Local
rails generate controller ControllerName action1 action2

# Docker
docker-compose exec web rails generate controller ControllerName action1 action2
```

### Running Console
```bash
# Local
make console

# Docker
make docker-console
```

## Testing

```bash
# Local
make test

# Docker
docker-compose exec web rails test
```

## Production Deployment

### Building for Production

The included `Dockerfile` is optimized for production deployment:

```bash
docker build -t ruby-budget .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=postgresql://user:pass@host:5432/dbname \
  ruby-budget
```

### Using Kamal

The project is pre-configured for Kamal deployment:

```bash
# Setup Kamal
bundle exec kamal setup

# Deploy
bundle exec kamal deploy
```

Edit `config/deploy.yml` to configure your deployment settings.

## Troubleshooting

### Port already in use
If port 3000 is already in use:
```bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9

# Or use a different port
rails server -p 3001
```

### Database connection issues
Make sure PostgreSQL is running:
```bash
# macOS
brew services start postgresql

# Ubuntu
sudo service postgresql start

# Docker
docker-compose up db
```

### Docker issues
```bash
# Rebuild from scratch
make docker-clean
make docker-build
make docker-up
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.
