# Savings Account Projection Feature Design

**Date:** 2025-11-01
**Feature:** Future balance projections for savings accounts

## Overview

This feature enables users to project future account balances based on expected monthly contributions and rate of return. Users can model different financial scenarios and see detailed month-by-month growth projections using compound interest calculations.

## Requirements

### Functional Requirements
- Store projection parameters per account (monthly contribution, annual return rate)
- Calculate projected balance to a user-specified target date
- Use compound interest calculation (interest on interest)
- Display final projected balance prominently
- Show detailed monthly breakdown of balance progression
- Allow editing projection parameters

### Non-Functional Requirements
- Calculation must be accurate and use standard compound interest formulas
- Service object pattern for maintainable, testable calculation logic
- Integrate seamlessly into existing account show page
- Support long-term projections (40+ years for retirement planning)

## Data Model

### Projection Model
```ruby
class Projection < ApplicationRecord
  belongs_to :account

  # Columns:
  # - account_id: integer (foreign key, indexed)
  # - monthly_contribution: decimal (expected monthly deposit)
  # - annual_return_rate: decimal (percentage, e.g., 5.0 for 5%)
  # - created_at, updated_at: timestamps
end
```

**Validations:**
- `monthly_contribution` must be present and >= 0
- `annual_return_rate` must be present (can be negative for conservative scenarios)
- Foreign key ensures account exists

### Account Model Updates
```ruby
class Account < ApplicationRecord
  has_many :adjustments, dependent: :destroy
  has_one :projection, dependent: :destroy
  # ... existing code
end
```

**Design Decision: has_one vs has_many**
- Using `has_one :projection` for initial implementation (one projection per account)
- Keeps UI simple and focused
- Database structure supports future extension to `has_many` for multiple scenarios
- Can add scenario names and switch to has_many without migration (just add column)

## Architecture

### Service Object: ProjectionCalculator

Handles compound interest calculations with monthly contributions:

```ruby
# app/services/projection_calculator.rb
class ProjectionCalculator
  def initialize(projection:, current_balance:, target_date:)
    @projection = projection
    @current_balance = current_balance
    @target_date = target_date
  end

  def calculate
    # Returns: { final_balance: Decimal, monthly_breakdown: Array }
  end
end
```

**Calculation Logic:**
1. Start with current account balance
2. For each month until target date:
   - Add monthly contribution
   - Apply compound interest: `balance * (annual_rate / 12 / 100)`
   - Record balance, contribution, and interest earned
3. Return final balance and full breakdown array

**Why Service Object:**
- Separates complex calculation logic from models/controllers
- Easy to test in isolation
- Simple to modify formula without touching other code
- Can be reused if we add projection features elsewhere

### Compound Interest Formula

Monthly rate: `r = (annual_return_rate / 100) / 12`

Each month:
1. `balance = balance + monthly_contribution`
2. `interest = balance * r`
3. `balance = balance + interest`

This compounds interest monthly on the growing balance (includes previous contributions + interest).

## Routes

```ruby
resources :accounts do
  resources :adjustments, only: [:new, :create]
  resource :projection, only: [:edit, :update]  # singular resource
end
```

**Generated Routes:**
- `GET /accounts/:account_id/projection/edit` - Projection settings form
- `PATCH /accounts/:account_id/projection` - Save projection settings

**Design Decision: Singular Resource**
- `resource :projection` (not `resources`) since account has_one projection
- URLs are cleaner: `/accounts/1/projection/edit` vs `/accounts/1/projections/1/edit`
- Controller is simpler (no need to find projection by id)

## Controllers

### ProjectionsController
```ruby
class ProjectionsController < ApplicationController
  before_action :set_account

  def edit
    @projection = @account.projection || @account.build_projection
  end

  def update
    @projection = @account.projection || @account.build_projection

    if @projection.update(projection_params)
      redirect_to @account, notice: 'Projection settings saved.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def projection_params
    params.require(:projection).permit(:monthly_contribution, :annual_return_rate)
  end
end
```

**Key Points:**
- Handles both creating first projection and updating existing one
- `build_projection` if none exists ensures form always works
- Standard Rails CRUD pattern for consistency

### AccountsController Updates
Add projection calculation to `show` action:

```ruby
def show
  @account = Account.find(params[:id])
  @adjustments = @account.adjustments.order(adjusted_at: :desc)

  # Calculate projection if parameters present
  if @account.projection && params[:target_date].present?
    target_date = Date.parse(params[:target_date])
    calculator = ProjectionCalculator.new(
      projection: @account.projection,
      current_balance: @account.balance,
      target_date: target_date
    )
    @projection_result = calculator.calculate
  end
end
```

## Views

### Account Show Page (`app/views/accounts/show.html.erb`)

**Structure:**
1. **Account Header** (existing)
   - Name, current balance, metadata

2. **Projection Parameters Section** (new)
   - If projection exists: Display monthly contribution and annual return rate
   - "Edit Projection" button → links to projection edit form
   - If no projection: "Set Up Projection" button

3. **Projection Calculator Section** (new, only if projection exists)
   - Form with target date picker field
   - "Calculate Projection" submit button
   - Results displayed when calculated:
     - **Prominent final balance display** (large text, highlighted)
     - **Monthly breakdown table**: Date | Starting Balance | Contribution | Interest | Ending Balance
     - Table scrollable for long projections

4. **Adjustment History** (existing, unchanged)

### Projection Edit Form (`app/views/projections/edit.html.erb`)

**Fields:**
- Monthly Contribution (decimal input, default 0)
  - Label: "Expected Monthly Contribution"
  - Help text: "Amount you plan to deposit each month"
- Annual Return Rate (decimal input, required)
  - Label: "Expected Annual Return Rate (%)"
  - Help text: "Enter as percentage (e.g., 5.0 for 5% annual returns)"
- Save button
- Cancel link back to account

**Form behavior:**
- Works for both creating first projection and editing existing
- Validates on submit, shows errors inline
- Redirects to account show page on success

## Testing Strategy

### Model Tests (`test/models/projection_test.rb`)
- Validation: monthly_contribution >= 0
- Validation: annual_return_rate presence
- Validation: prevents multiple projections per account (via has_one)
- Association: belongs_to account
- Association: destroyed when account destroyed

### Service Tests (`test/services/projection_calculator_test.rb`)

**Core Calculations:**
- Zero contribution, zero return → flat balance
- Positive contribution, zero return → linear growth (contribution × months)
- Zero contribution, positive return → compound interest on initial balance only
- Positive contribution, positive return → full compound growth
- Negative return rate → declining balance (bear market scenario)

**Edge Cases:**
- One month projection
- Multi-year projection (40+ years)
- Very high return rates
- Very small balances (decimal precision)

**Accuracy Checks:**
- Final balance matches sum of contributions + interest
- Monthly breakdown last entry matches final_balance
- Interest calculations compound correctly month-over-month

### Controller Tests (`test/controllers/projections_controller_test.rb`)
- GET edit: renders form
- GET edit: builds projection if account has none
- PATCH update: creates projection with valid params
- PATCH update: updates existing projection
- PATCH update: renders errors with invalid params (negative contribution)
- Redirects to account show after save

### System Tests (`test/system/projections_test.rb`)

**User Workflows:**
1. Create account → Visit show → See "No projection configured" message
2. Click "Set Up Projection" → Fill form (contribution: 500, rate: 5.0) → Save
3. Verify projection parameters displayed on account page
4. Enter target date (5 years future) → Click Calculate
5. Verify final balance displayed prominently
6. Verify monthly breakdown table shows all months
7. Edit projection → Change parameters → Recalculate → Verify results updated
8. Test validation: Try negative contribution → See error message
9. Test validation: Try past target date → See error message

## Edge Cases & Validation

### Input Validation
- **Target date in past:** Show error "Target date must be in the future"
- **Target date is today:** Show current balance (no calculation needed)
- **Missing target date:** Don't show calculation results
- **Negative monthly contribution:** Validation error
- **Missing annual return rate:** Validation error

### Display Considerations
- **Long projections (40+ years):** Monthly table could have 480+ rows
  - Consider pagination or yearly summary view
  - Initial implementation: show all months (test with real data)
- **Decimal precision:** Round all displayed values to 2 decimal places
  - Use banker's rounding to minimize accumulation errors
- **Large balances:** Format with commas (e.g., $1,234,567.89)

## Future Enhancements

Not in scope for initial implementation:

1. **Multiple Projection Scenarios**
   - Change `has_one` to `has_many`
   - Add scenario name field
   - Add scenario comparison view

2. **Variable Contributions**
   - Allow contribution to change over time
   - Model contribution increases (e.g., 3% annual raise)

3. **Visualization**
   - Chart showing balance growth curve
   - Compare actual vs projected over time

4. **Goal Tracking**
   - Set target balance goal
   - Calculate required contribution to reach goal by date

5. **Tax Considerations**
   - Model tax-advantaged accounts (IRA, 401k)
   - Account for capital gains taxes on returns

6. **Inflation Adjustment**
   - Show "real" returns adjusted for inflation
   - Project purchasing power, not just nominal balance

## Summary

This design adds projection capability to savings accounts using:

- **Clean data model:** Separate Projection model with has_one relationship
- **Maintainable calculations:** Service object with standard compound interest formula
- **Integrated UI:** Projection features embedded in existing account show page
- **Comprehensive testing:** Model, service, controller, and system test coverage

The architecture supports future extension to multiple scenarios, visualization, and advanced features while keeping the initial implementation focused and simple.

**Key Trade-offs:**
- ✅ Service object adds complexity but improves testability and maintainability
- ✅ has_one simplifies UI now, easy to extend to has_many later
- ✅ Monthly breakdown provides detail but could be large for long projections
- ✅ Calculation on-demand keeps database simple (no stored results to maintain)
