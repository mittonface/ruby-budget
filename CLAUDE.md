# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby Budget is a Rails 8.1 application for tracking savings accounts and mortgages with projections. The core domain consists of:

- **Accounts**: Base model for both savings accounts and mortgages using Single Table Inheritance (STI)
- **SavingsAccount**: Asset accounts with positive balances
- **Mortgage**: Debt accounts tracking loan principal, interest, and amortization
- **Adjustments**: Balance changes (deposits/withdrawals/payments) on accounts
- **Projections**: Future balance calculations based on monthly contributions and return rates

The application uses PostgreSQL, Tailwind CSS, Hotwire (Turbo + Stimulus), and modern Rails conventions.

## Essential Commands

### Local Development (without Docker)
```bash
# Initial setup
bundle install
bin/rails db:create db:migrate db:seed

# Start development server (Rails + Tailwind watcher)
bin/dev

# Rails console
bin/rails console

# Run specific test file
bin/rails test test/models/account_test.rb

# Run all tests
bin/rails test && bin/rails test:system

# Linting
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix
```

### Docker Development (Preferred)
```bash
# Setup and start
docker-compose up -d
docker-compose exec web rails db:create db:migrate db:seed

# Run tests in Docker
docker-compose exec web rails test
docker-compose exec web rails test:system

# Rails console
docker-compose exec web rails console

# Shell access
docker-compose exec web bash
```

### CI/CD Pipeline
The CI workflow runs:
1. Security scans (Brakeman, bundler-audit, importmap audit)
2. RuboCop linting
3. **Tailwind CSS build** (required before tests)
4. All tests (unit + system tests)

**Important**: Always run `bin/rails tailwindcss:build` before running tests in CI or after CSS changes.

## Architecture

### Domain Models

**Account** (app/models/account.rb)
- Base model using Single Table Inheritance (STI) with `type` discriminator column
- Has many adjustments (balance changes)
- Has one projection (future balance calculations)
- Subclasses: SavingsAccount, Mortgage
- Validates: name, balance, initial_balance, opened_at

**SavingsAccount** (app/models/savings_account.rb)
- Inherits from Account
- Represents asset accounts with positive balances
- Used for tracking savings, emergency funds, etc.

**Mortgage** (app/models/mortgage.rb)
- Inherits from Account
- Represents debt accounts (liabilities)
- Additional fields: principal, interest_rate, term_years, loan_start_date
- Additional validations: principal > 0, interest_rate >= 0, term_years > 0
- Balance represents remaining principal owed

**Adjustment** (app/models/adjustment.rb)
- Belongs to an account (polymorphic - works with both SavingsAccount and Mortgage)
- Records deposits/withdrawals/payments with timestamp
- Default scope: ordered by adjusted_at descending
- Validates: amount (non-zero), adjusted_at

**Projection** (app/models/projection.rb)
- Belongs to an account (polymorphic - works with both SavingsAccount and Mortgage)
- Stores monthly_contribution and annual_return_rate
- For savings: used for compound interest projections
- For mortgages: used for extra payment scenarios
- Used by ProjectionCalculator and MortgageCalculator services

### Service Layer

**ProjectionCalculator** (app/services/projection_calculator.rb)
- Calculates future savings account balances using compound interest
- Takes: projection, current_balance, target_date
- Returns: final_balance and monthly_breakdown with contributions/interest
- Algorithm:
  1. Add monthly contribution
  2. Apply compound interest (annual_return_rate / 12)
  3. Track breakdown for each month

**MortgageCalculator** (app/services/mortgage_calculator.rb)
- Calculates mortgage-specific financial data
- Methods:
  - `calculate_monthly_payment`: Required monthly payment using standard amortization formula: M = P * [r(1+r)^n] / [(1+r)^n - 1]
  - `calculate_payment_breakdown`: Principal vs interest split for next payment based on current balance
  - `generate_amortization_schedule(num_months)`: Month-by-month payment breakdown showing balance reduction
  - `calculate_payoff_date`: Estimated payoff date considering current balance and payment plan
- Supports extra payments via Projection model (monthly_contribution becomes extra principal payment)
- Handles zero interest rate edge case

Note: `app/services` is autoloaded via config/application.rb:40

### Routes Structure

```ruby
resources :accounts do
  resources :adjustments, only: [:new, :create]
  resource :projection, only: [:edit, :update]
end
```

- Root path: accounts#index
- Nested resources for account-specific adjustments and projection
- Projection is singular resource (one per account)

### Controllers

**AccountsController** - Full CRUD for accounts with STI support
- `index`: Separates accounts by type (savings vs mortgages), calculates net worth
- `create`: Type-aware account creation, instantiates correct subclass
- `show`: Type-aware display, runs MortgageCalculator for mortgages, ProjectionCalculator for savings
- Permits type-specific parameters conditionally

**AdjustmentsController** - Create new balance adjustments/payments (nested under accounts)
**ProjectionsController** - Edit/update projection settings for compound interest calculations or extra mortgage payments

### Testing

Tests use the standard Rails minitest framework:
- `test/models/` - Model tests
- `test/controllers/` - Controller tests
- `test/system/` - System tests (Capybara + Selenium)
- `test/services/` - Service object tests

Parallel test execution is enabled (test_helper.rb:8).

**Running specific test types**:
```bash
bin/rails test:models
bin/rails test:system
bin/rails test test/path/to/specific_test.rb
```

### Database

PostgreSQL database with three main tables:
- `accounts` - Account records with STI (type column for SavingsAccount/Mortgage discrimination)
  - Mortgage-specific columns: principal, interest_rate, term_years, loan_start_date
  - Indexed on type for efficient querying
- `adjustments` - Balance change history (deposits/withdrawals/payments)
- `projections` - Future projection settings (compound interest or extra payments)

Database configuration in `config/database.yml` uses `DATABASE_URL` environment variable in Docker/CI environments.

### Frontend Stack

- **Tailwind CSS**: Utility-first CSS framework
  - Build command: `bin/rails tailwindcss:build`
  - Watcher runs via `bin/dev` in development
- **Hotwire/Turbo**: For SPA-like page navigation without full page reloads
- **Stimulus**: Lightweight JavaScript framework for sprinkles of interactivity
- **Importmap**: JavaScript module imports without bundling

## Development Workflow

### Adding Features

1. Generate migration: `bin/rails generate migration MigrationName`
2. Run migration: `bin/rails db:migrate`
3. Write tests in appropriate test/ subdirectory
4. Implement feature
5. Run tests: `bin/rails test`
6. Run linter: `bundle exec rubocop -A`

### Running Single Tests

For faster iteration on specific features:
```bash
# Run single test file
bin/rails test test/models/account_test.rb
bin/rails test test/models/mortgage_test.rb
bin/rails test test/services/mortgage_calculator_test.rb

# Run single test method
bin/rails test test/models/account_test.rb:10
```

### Service Objects

When adding business logic that doesn't belong in models:
1. Create file in `app/services/`
2. Follow pattern: plain Ruby class with `initialize` and primary method
3. Services are autoloaded (config in application.rb)

### Security Scanning

The project uses multiple security tools:
- Brakeman (static analysis for Rails vulnerabilities)
- bundler-audit (known gem vulnerabilities)
- importmap audit (JavaScript dependency vulnerabilities)

Run locally: `bin/brakeman`, `bin/bundler-audit`

## Key Conventions

- Use `default_scope` for consistent ordering (see Adjustment model)
- Validations on all model attributes with presence/numericality checks
- Service objects for complex calculations (ProjectionCalculator, MortgageCalculator pattern)
- Nested resources for has_many relationships (accounts/adjustments)
- Singular resources for has_one relationships (account/projection)
- Single Table Inheritance (STI) for account types with type-specific validations in subclasses
- Balance semantics: positive for assets (SavingsAccount), positive for liabilities (Mortgage remaining principal)
- Net worth calculation: sum(savings balances) - sum(mortgage balances)
