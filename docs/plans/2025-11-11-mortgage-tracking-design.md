# Mortgage Tracking Design

**Date:** 2025-11-11
**Status:** Approved

## Overview

Add mortgage tracking capability to Ruby Budget using Single Table Inheritance (STI) to treat mortgages as a type of account alongside existing savings accounts.

## Requirements

- Track mortgage loan details (principal, interest rate, term)
- Calculate amortization projections (payment schedule, payoff date)
- Reuse existing Adjustments model for payment tracking
- Maintain compatibility with existing savings accounts

## Architecture

### Data Model (Single Table Inheritance)

**Schema Changes to `accounts` table:**
- Add `type` column (string) for STI discrimination
- Add mortgage-specific columns:
  - `principal` (decimal, precision: 10, scale: 2) - original loan amount
  - `interest_rate` (decimal, precision: 5, scale: 3) - annual rate (e.g., 3.500%)
  - `term_years` (integer) - loan term in years
  - `loan_start_date` (date) - mortgage origination date

**Model Hierarchy:**
```
Account (base class)
├── SavingsAccount (explicit subclass for existing accounts)
└── Mortgage (new subclass for debt tracking)
```

**Key Behaviors:**
- **SavingsAccount:** balance = asset value (positive)
- **Mortgage:** balance = remaining principal owed (treated as liability)
- Both types use `has_many :adjustments` for transaction history
- Both types use `has_one :projection` for future calculations

**Adjustment Semantics for Mortgages:**
- Negative adjustments = regular payments reducing balance
- Positive adjustments = additional borrowing or fees increasing balance

### Service Layer

**MortgageCalculator** (app/services/mortgage_calculator.rb):

Handles amortization math similar to existing `ProjectionCalculator` pattern.

**Key Methods:**
1. `calculate_monthly_payment(mortgage)` → Returns required monthly payment amount
2. `calculate_payment_breakdown(mortgage, payment_date)` → Returns hash with principal_portion and interest_portion for a specific payment
3. `generate_amortization_schedule(mortgage, num_months)` → Returns array of monthly payment objects showing balance reduction over time
4. `calculate_payoff_date(mortgage)` → Predicts loan payoff date based on current balance and payment schedule

**Algorithm:**
```
monthly_rate = (interest_rate / 12) / 100
n = term_years * 12
monthly_payment = principal * [r(1+r)^n] / [(1+r)^n - 1]

For each payment:
  interest_portion = current_balance * monthly_rate
  principal_portion = monthly_payment - interest_portion
  new_balance = current_balance - principal_portion
```

**Integration with Projections:**
- Reuse existing `Projection` model (polymorphic relationship)
- `projection.monthly_contribution` represents extra principal payment amount
- Calculator factors in extra payments for accelerated payoff scenarios

### Controllers

**No new controllers needed** - STI means mortgages flow through existing controllers:

**AccountsController:**
- Update strong params to permit: `type, principal, interest_rate, term_years, loan_start_date`
- Add conditional logic in `create`/`update`:
  - For Mortgage type: set `balance = principal` on creation
  - For SavingsAccount type: existing behavior unchanged

**AdjustmentsController:**
- No changes needed (works for both account types)

**ProjectionsController:**
- No changes needed (works for both account types)

### Routes

No changes to routes - STI uses existing structure:
```ruby
resources :accounts do
  resources :adjustments, only: [:new, :create]
  resource :projection, only: [:edit, :update]
end
```

### User Interface

**Accounts Index** (app/views/accounts/index.html.erb):
- Split display into two sections: "Savings Accounts" and "Mortgages"
- Filter accounts by type: `@savings = Account.where(type: 'SavingsAccount')`
- Display savings with positive balance (assets)
- Display mortgages showing "Amount Owed: $X" (liability)
- Add net worth summary: `sum(savings.balance) - sum(mortgages.balance)`

**Account Form** (new/edit):
- Add account type selector:
  - Radio buttons: "Savings Account" / "Mortgage"
  - Default to SavingsAccount for new records
- Conditionally show fields using Stimulus controller:
  - Always visible: name, opened_at
  - Savings fields: balance, initial_balance
  - Mortgage fields: principal, interest_rate, term_years, loan_start_date
- JavaScript toggles field visibility based on type selection

**Mortgage Show Page:**
- Display loan summary:
  - Original Principal: $X
  - Interest Rate: Y%
  - Term: Z years
  - Start Date: MM/DD/YYYY
- Display current status:
  - Remaining Balance: $X
  - Months Remaining: N
  - Monthly Payment: $X
- Show amortization chart:
  - Reuse projection chart pattern from existing savings features
  - X-axis: months, Y-axis: balance
  - Show principal vs interest breakdown over time
- Links to existing features:
  - "Record Payment" → adjustments/new
  - "Extra Payment Scenarios" → projection/edit

**Styling:**
- Savings accounts: green/positive theme (existing)
- Mortgages: red/debt theme (new color scheme)
- Net worth: neutral theme, highlight positive/negative

### Data Migration Strategy

**Migration 1: Add STI and mortgage fields**
```ruby
class AddMortgageFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :type, :string
    add_column :accounts, :principal, :decimal, precision: 10, scale: 2
    add_column :accounts, :interest_rate, :decimal, precision: 5, scale: 3
    add_column :accounts, :term_years, :integer
    add_column :accounts, :loan_start_date, :date

    add_index :accounts, :type
  end
end
```

**Migration 2: Set type for existing records**
```ruby
class SetTypeForExistingAccounts < ActiveRecord::Migration[8.1]
  def up
    Account.update_all(type: 'SavingsAccount')
  end

  def down
    Account.update_all(type: nil)
  end
end
```

**Backwards Compatibility:**
- All existing Account queries continue to work (returns all types)
- Existing adjustments, projections remain associated correctly
- No changes required to existing test data or fixtures

## Testing Strategy

### Model Tests

**test/models/mortgage_test.rb:**
- Validate presence of mortgage-specific fields
- Test balance calculations (balance should equal remaining principal)
- Verify inheritance from Account
- Test validations (interest_rate > 0, term_years > 0, etc.)

**test/models/savings_account_test.rb:**
- Ensure existing account behavior works under STI
- Verify savings-specific validations still apply

**test/models/account_test.rb:**
- Update to test shared behavior across both types
- Test STI queries (Account.all, SavingsAccount.all, Mortgage.all)

### Service Tests

**test/services/mortgage_calculator_test.rb:**
- Test monthly payment calculation accuracy against known values
- Test amortization schedule generation (verify math)
- Test extra payment scenarios (accelerated payoff)
- Test edge cases:
  - Zero interest rate
  - Large principal amounts
  - Short vs long terms

### Controller Tests

**test/controllers/accounts_controller_test.rb:**
- Test creating SavingsAccount (existing behavior)
- Test creating Mortgage with mortgage-specific params
- Test updating both account types
- Test strong params permit mortgage fields

### System Tests

**test/system/mortgages_test.rb:**
- End-to-end: Create mortgage → Record payment → View amortization
- Test account type toggle in form (JavaScript behavior)
- Verify mortgage appears in mortgages section on index
- Test net worth calculation accuracy

**test/system/accounts_test.rb:**
- Update existing tests to work with STI
- Test filtering by account type on index page

## Implementation Phases

### Phase 1: Core STI Setup
1. Generate and run migrations (add type + mortgage fields)
2. Create SavingsAccount and Mortgage models
3. Update Account model validations
4. Write model tests

### Phase 2: Calculation Service
1. Create MortgageCalculator service
2. Implement amortization algorithms
3. Write service tests

### Phase 3: Controllers & Routes
1. Update AccountsController strong params
2. Add conditional logic for mortgage creation
3. Write controller tests

### Phase 4: User Interface
1. Update accounts index (split savings/mortgages)
2. Create account type selector in form
3. Add Stimulus controller for field toggling
4. Create mortgage show page with amortization chart
5. Write system tests

### Phase 5: Polish & Documentation
1. Add styling for mortgage vs savings distinction
2. Update CLAUDE.md with mortgage information
3. Manual testing of full workflow
4. Performance check with mixed account types

## Success Criteria

- ✅ Can create mortgage with loan details
- ✅ Can record payments as negative adjustments
- ✅ Amortization calculations are mathematically correct
- ✅ Mortgage balance updates correctly after payments
- ✅ Can view amortization schedule with principal/interest breakdown
- ✅ Net worth calculation includes mortgages as liabilities
- ✅ All existing savings account features continue to work
- ✅ All tests pass (unit, controller, system)

## Future Enhancements (Out of Scope)

- Property value tracking
- Escrow account management
- Refinancing scenarios
- Multiple mortgages on single property
- Tax/insurance payment tracking
- Payment history import from lender
