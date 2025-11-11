# Set Balance Feature Design

**Date:** 2025-11-10
**Status:** Approved

## Overview

Add ability to set an account's current balance directly instead of entering manual adjustments. The system will automatically calculate and create the adjustment based on the difference between current and new balance.

## Requirements

- Replace the adjustment form with a dual-mode interface
- Toggle between "Add Adjustment" (existing) and "Set Balance" (new)
- When setting balance, automatically calculate adjustment amount
- Use current timestamp for auto-calculated adjustments
- Maintain existing validation and transaction logic

## User Interface

### Form Toggle

Radio buttons at top of adjustment form:
- **"Add Adjustment"** (default) - Shows amount field (existing behavior)
- **"Set Balance"** - Shows new_balance field

### Mode 1: Add Adjustment (Existing)
```
Amount: [____] (positive or negative number)
Description: [____] (optional)
```

### Mode 2: Set Balance (New)
```
New Balance: [____] (absolute value)
Description: [____] (optional, e.g., "Corrected balance")
```

Only one set of fields visible at a time based on toggle selection.

## Backend Implementation

### Controller Changes (AdjustmentsController)

Modify the `create` action to handle two modes:

```ruby
def create
  if params[:adjustment][:new_balance].present?
    # Set Balance mode
    new_balance = params[:adjustment][:new_balance].to_f
    calculated_amount = new_balance - @account.balance
    @adjustment = @account.adjustments.new(
      amount: calculated_amount,
      description: params[:adjustment][:description],
      adjusted_at: Time.current
    )
  else
    # Add Adjustment mode (existing)
    @adjustment = @account.adjustments.new(adjustment_params)
  end

  Account.transaction do
    @adjustment.save!
    @account.update!(balance: @account.balance + @adjustment.amount)
  end

  redirect_to @account, notice: "Adjustment was successfully added."
rescue ActiveRecord::RecordInvalid
  render :new, status: :unprocessable_entity
end
```

### Strong Parameters

Add `:new_balance` to permitted params:

```ruby
def adjustment_params
  params.require(:adjustment).permit(:amount, :new_balance, :description, :adjusted_at)
end
```

### Validation

Existing validation on Adjustment model (`amount != 0`) prevents creating adjustments when new_balance equals current balance. No additional validation needed.

## Frontend Implementation

### Stimulus Controller

Create `app/javascript/controllers/adjustment_form_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amountField", "balanceField", "amountInput", "balanceInput"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const mode = this.element.querySelector('input[name="mode"]:checked').value

    if (mode === "set_balance") {
      this.amountFieldTarget.classList.add("hidden")
      this.balanceFieldTarget.classList.remove("hidden")
      this.amountInputTarget.value = "" // Clear amount when switching
    } else {
      this.amountFieldTarget.classList.remove("hidden")
      this.balanceFieldTarget.classList.add("hidden")
      this.balanceInputTarget.value = "" // Clear balance when switching
    }
  }
}
```

### View Changes

Modify `app/views/adjustments/new.html.erb`:

1. Add radio buttons with toggle action
2. Wrap amount field with Stimulus target and appropriate visibility
3. Add new_balance field with Stimulus target (initially hidden)
4. Both inputs need targets for value clearing

## Error Handling

### Edge Cases

1. **New balance equals current balance**
   - Calculated amount = 0
   - Existing validation rejects with "Amount can't be 0"

2. **Invalid new_balance input**
   - Rails type coercion handles non-numeric input
   - Empty string becomes 0.0

3. **Both amount and new_balance provided**
   - Controller prioritizes `new_balance` if present
   - Ignores `amount` parameter in this case

### User Feedback

- Success: "Adjustment was successfully added." (existing message)
- Validation errors display inline (existing Rails behavior)
- Consider showing calculated adjustment in confirmation

## Testing Strategy

### Controller Tests
- Test "Add Adjustment" mode (existing behavior)
- Test "Set Balance" mode with valid new_balance
- Test validation error when new_balance equals current balance
- Test both modes create correct adjustment amounts

### System Tests
- Toggle switches between modes correctly
- Amount field hidden when "Set Balance" selected
- Balance field hidden when "Add Adjustment" selected
- Form submits successfully in both modes
- Cleared values when switching modes

### Edge Case Tests
- New balance equals current balance shows validation error
- Non-numeric input handled gracefully
- Transaction rollback on validation failure

## Components Modified

- `app/controllers/adjustments_controller.rb` - Add conditional logic for new_balance
- `app/views/adjustments/new.html.erb` - Add toggle and new_balance field
- `app/javascript/controllers/adjustment_form_controller.js` - New Stimulus controller
- `test/controllers/adjustments_controller_test.rb` - Add tests for both modes
- `test/system/adjustments_test.rb` - Add system tests for toggle behavior

## Migration Required

No database changes required. The `new_balance` parameter is transient and used only for calculation.
