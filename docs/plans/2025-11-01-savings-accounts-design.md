# Savings Account Management Design

**Date:** 2025-11-01
**Feature:** Savings account tracking with adjustment history

## Overview

This feature enables household financial planning through savings account management. Users can create savings accounts, track balances, and maintain a complete history of all balance adjustments.

## Requirements

### Functional Requirements
- Create savings accounts with name and initial balance
- View list of all accounts with current balances
- Adjust account balances (deposits and withdrawals)
- Track all adjustments with timestamps and descriptions
- View account history with running balance after each adjustment

### Non-Functional Requirements
- Web-based interface
- Data consistency between balance and adjustment history
- Fast balance queries

## Data Model

### Account Model
```ruby
class Account < ApplicationRecord
  has_many :adjustments, dependent: :destroy

  # Columns:
  # - name: string (required)
  # - balance: decimal (cached for performance)
  # - initial_balance: decimal (opening balance)
  # - opened_at: datetime (when account was opened)
  # - created_at, updated_at: timestamps
end
```

**Validations:**
- `name` must be present
- `balance` and `initial_balance` must be valid decimal numbers
- `opened_at` must be present

### Adjustment Model
```ruby
class Adjustment < ApplicationRecord
  belongs_to :account

  # Columns:
  # - account_id: integer (foreign key)
  # - amount: decimal (signed: positive for deposits, negative for withdrawals)
  # - description: text (optional note)
  # - adjusted_at: datetime (when adjustment occurred)
  # - created_at, updated_at: timestamps
end
```

**Validations:**
- `amount` must be present and non-zero
- `account_id` must be present (validated by belongs_to)
- `adjusted_at` must be present

## Architecture Decision: Cached Balance

We're using a cached balance approach where:
- Account model stores `balance` field
- Balance is updated atomically when adjustments are created
- Database transactions ensure consistency

**Trade-offs:**
- ✅ Fast balance queries (no summing required)
- ✅ Simple to display current balance
- ⚠️ Requires careful transaction handling
- ⚠️ Balance and adjustments must stay in sync

**Transaction Safety:**
All adjustment creation operations wrap in `Account.transaction` to ensure:
1. Adjustment record is saved
2. Account balance is updated by the adjustment amount
3. If either operation fails, both roll back

## Routes

```ruby
resources :accounts do
  resources :adjustments, only: [:new, :create]
end
```

**Generated Routes:**
- `GET /accounts` - List all accounts
- `GET /accounts/new` - New account form
- `POST /accounts` - Create account
- `GET /accounts/:id` - Account details with history
- `GET /accounts/:id/edit` - Edit account form
- `PATCH /accounts/:id` - Update account
- `DELETE /accounts/:id` - Delete account
- `GET /accounts/:id/adjustments/new` - New adjustment form
- `POST /accounts/:id/adjustments` - Create adjustment

## Controllers

### AccountsController
Standard Rails CRUD controller for account management:
- `index`: Display all accounts
- `show`: Display account details and adjustment history
- `new`/`create`: Create new account with initial balance
- `edit`/`update`: Modify account metadata
- `destroy`: Delete account and all adjustments

### AdjustmentsController
Handles adjustment creation with balance updates:
- `new`: Form to create adjustment
- `create`: Create adjustment within transaction, update account balance

**Critical Implementation (AdjustmentsController#create):**
```ruby
def create
  @account = Account.find(params[:account_id])

  Account.transaction do
    @adjustment = @account.adjustments.build(adjustment_params)
    @adjustment.save!
    @account.update!(balance: @account.balance + @adjustment.amount)
  end

  redirect_to @account, notice: 'Adjustment added successfully.'
rescue ActiveRecord::RecordInvalid => e
  render :new, status: :unprocessable_entity
end
```

## Views

### Accounts Index (`app/views/accounts/index.html.erb`)
Table view showing:
- Account name (linked to show page)
- Current balance
- Opened date
- "New Account" button

### Account Show (`app/views/accounts/show.html.erb`)
Displays:
- **Header:** Account name and prominent current balance
- **Metadata:** Opened date, initial balance
- **Actions:** "Add Adjustment" button, edit/delete links
- **History Table:**
  - Columns: Date, Description, Amount, Running Balance
  - Sorted newest first
  - Running balance calculated by iterating adjustments in reverse

### Account Form (`app/views/accounts/_form.html.erb`)
Fields:
- Name (text, required)
- Initial Balance (decimal, required, defaults to 0)
- Opened Date (date, defaults to today)

### Adjustment Form (`app/views/adjustments/new.html.erb`)
Fields:
- Current balance displayed (read-only)
- Amount (decimal, required, accepts positive or negative)
- Description (textarea, optional)
- Date (datetime, defaults to now)

## Testing Strategy

### Model Tests
- Account validations
- Adjustment validations
- Association integrity
- Balance calculation logic

### Controller Tests
- All CRUD operations for accounts
- Adjustment creation updates balance correctly
- Transaction rollback on validation failures
- Error handling

### System Tests
**Key User Workflows:**
1. Create account → Verify initial balance set
2. Create account → Add positive adjustment → Verify balance increases
3. Create account → Add negative adjustment → Verify balance decreases
4. Create multiple adjustments → Verify running balance calculations
5. Concurrent adjustments (edge case testing)

### Critical Test Case: Transaction Safety
Test that concurrent adjustment attempts don't corrupt balance:
- Use database-level locking or optimistic locking
- Verify balance equals sum of initial_balance + all adjustments

## Future Considerations

Not in scope for initial implementation:
- Multiple account types (checking, investment, etc.)
- Transfers between accounts
- Recurring adjustments
- Budgeting and forecasting
- Multi-user/household support
- Account reconciliation

These can be added incrementally based on user needs.

## Summary

This design provides a solid foundation for savings account tracking with:
- Clean data model with cached balance for performance
- Transaction-safe adjustment creation
- Complete audit history
- User-friendly web interface
- Comprehensive test coverage

The cached balance approach trades some complexity for query performance, which is appropriate for a household planning application with relatively low transaction volume.
