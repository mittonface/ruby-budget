# Savings Account Projections Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add future balance projection capability to savings accounts with compound interest calculations.

**Architecture:** Separate Projection model (has_one relationship with Account) + ProjectionCalculator service object for compound interest math + UI integrated into account show page.

**Tech Stack:** Ruby on Rails 8.0, SQLite, Capybara for system tests

---

## Task 1: Create Projection Model and Migration

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_create_projections.rb`
- Create: `app/models/projection.rb`
- Create: `test/models/projection_test.rb`
- Modify: `app/models/account.rb:2` (add has_one association)

**Step 1: Generate migration**

Run:
```bash
bin/rails generate migration CreateProjections account:references monthly_contribution:decimal annual_return_rate:decimal
```

Expected: Migration file created in `db/migrate/`

**Step 2: Modify migration to add validations and precision**

Edit the generated migration file to look like this:

```ruby
class CreateProjections < ActiveRecord::Migration[8.0]
  def change
    create_table :projections do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.decimal :monthly_contribution, precision: 10, scale: 2, null: false, default: 0
      t.decimal :annual_return_rate, precision: 5, scale: 2, null: false

      t.timestamps
    end
  end
end
```

**Step 3: Run migration**

Run:
```bash
bin/rails db:migrate
```

Expected: Migration runs successfully, `projections` table created

**Step 4: Write Projection model with validations**

Create `app/models/projection.rb`:

```ruby
class Projection < ApplicationRecord
  belongs_to :account

  validates :monthly_contribution, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :annual_return_rate, presence: true, numericality: true
end
```

**Step 5: Add has_one association to Account model**

Modify `app/models/account.rb:2` (after `has_many :adjustments`):

```ruby
class Account < ApplicationRecord
  has_many :adjustments, dependent: :destroy
  has_one :projection, dependent: :destroy

  # ... rest of existing code
end
```

**Step 6: Write model tests**

Create `test/models/projection_test.rb`:

```ruby
require "test_helper"

class ProjectionTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
  end

  test "valid projection" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert projection.valid?
  end

  test "requires account" do
    projection = Projection.new(
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:account], "must exist"
  end

  test "requires monthly_contribution" do
    projection = Projection.new(
      account: @account,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:monthly_contribution], "can't be blank"
  end

  test "monthly_contribution must be non-negative" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: -100,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:monthly_contribution], "must be greater than or equal to 0"
  end

  test "allows zero monthly_contribution" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 0,
      annual_return_rate: 5.0
    )
    assert projection.valid?
  end

  test "requires annual_return_rate" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00
    )
    assert_not projection.valid?
    assert_includes projection.errors[:annual_return_rate], "can't be blank"
  end

  test "allows negative annual_return_rate" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: -2.0
    )
    assert projection.valid?
  end

  test "destroyed when account destroyed" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert_difference("Projection.count", -1) do
      @account.destroy
    end
  end

  test "account can have only one projection" do
    Projection.create!(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )

    # Attempting to create a second projection should fail at DB level
    # due to unique index on account_id
    second_projection = Projection.new(
      account: @account,
      monthly_contribution: 1000.00,
      annual_return_rate: 7.0
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      second_projection.save(validate: false)
    end
  end
end
```

**Step 7: Run tests**

Run:
```bash
bin/rails test test/models/projection_test.rb
```

Expected: All tests pass (9 tests)

**Step 8: Commit**

Run:
```bash
git add db/migrate/ app/models/projection.rb app/models/account.rb test/models/projection_test.rb db/schema.rb
git commit -m "Add Projection model with validations and tests"
```

---

## Task 2: Create ProjectionCalculator Service

**Files:**
- Create: `app/services/projection_calculator.rb`
- Create: `test/services/projection_calculator_test.rb`

**Step 1: Create services directory**

Run:
```bash
mkdir -p app/services
mkdir -p test/services
```

**Step 2: Write ProjectionCalculator service**

Create `app/services/projection_calculator.rb`:

```ruby
class ProjectionCalculator
  def initialize(projection:, current_balance:, target_date:)
    @projection = projection
    @current_balance = current_balance.to_d
    @target_date = target_date
  end

  def calculate
    balance = @current_balance
    monthly_rate = (@projection.annual_return_rate / 100.0) / 12.0
    breakdown = []

    current_date = Date.today

    while current_date <= @target_date
      # Add monthly contribution first
      balance += @projection.monthly_contribution

      # Apply compound interest
      interest = balance * monthly_rate
      balance += interest

      breakdown << {
        date: current_date,
        balance: balance.round(2),
        contribution: @projection.monthly_contribution.round(2),
        interest: interest.round(2)
      }

      current_date = current_date.next_month
    end

    {
      final_balance: balance.round(2),
      monthly_breakdown: breakdown
    }
  end
end
```

**Step 3: Write service tests**

Create `test/services/projection_calculator_test.rb`:

```ruby
require "test_helper"

class ProjectionCalculatorTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
  end

  test "zero contribution and zero return results in flat balance" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 0,
      annual_return_rate: 0
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today + 12.months
    )

    result = calculator.calculate

    assert_equal 1000.00, result[:final_balance]
    assert_equal 13, result[:monthly_breakdown].length # Today + 12 months
  end

  test "positive contribution with zero return gives linear growth" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 100,
      annual_return_rate: 0
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today + 12.months
    )

    result = calculator.calculate

    # 1000 + (100 * 13) = 2300
    assert_equal 2300.00, result[:final_balance]
  end

  test "zero contribution with positive return gives compound interest on initial balance" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 0,
      annual_return_rate: 12.0 # 1% per month for easier calculation
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today + 1.month
    )

    result = calculator.calculate

    # 1000 * (1 + 0.01)^2 = 1000 * 1.0201 = 1020.10
    # Why ^2? Because we calculate at today AND one month from now
    assert_in_delta 1020.10, result[:final_balance], 0.01
  end

  test "positive contribution with positive return gives full compound growth" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 6.0 # 0.5% per month
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 10000.00,
      target_date: Date.today + 12.months
    )

    result = calculator.calculate

    # Should be greater than linear growth: 10000 + (500 * 13) = 16500
    assert_operator result[:final_balance], :>, 16500.00

    # But not unreasonably high (sanity check)
    assert_operator result[:final_balance], :<, 17500.00

    # Verify it's around the expected compound value
    assert_in_delta 17166.62, result[:final_balance], 50.00
  end

  test "negative return rate results in declining balance" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 0,
      annual_return_rate: -12.0 # -1% per month
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today + 6.months
    )

    result = calculator.calculate

    # Balance should decrease
    assert_operator result[:final_balance], :<, 1000.00
  end

  test "one month projection" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 100,
      annual_return_rate: 6.0
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today
    )

    result = calculator.calculate

    assert_equal 1, result[:monthly_breakdown].length

    # 1000 + 100 = 1100, then 1100 * 0.005 = 5.50 interest
    assert_in_delta 1105.50, result[:final_balance], 0.01
  end

  test "multi-year projection" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 7.0
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 10000.00,
      target_date: Date.today + 40.years
    )

    result = calculator.calculate

    # Should have 481 months (today + 480 more months)
    assert_equal 481, result[:monthly_breakdown].length

    # With compound interest over 40 years, should be substantial
    assert_operator result[:final_balance], :>, 500000.00
  end

  test "monthly breakdown last entry matches final balance" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 250,
      annual_return_rate: 5.0
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 5000.00,
      target_date: Date.today + 24.months
    )

    result = calculator.calculate

    last_month = result[:monthly_breakdown].last
    assert_equal result[:final_balance], last_month[:balance]
  end

  test "breakdown shows contribution and interest each month" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 100,
      annual_return_rate: 12.0 # 1% per month
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 1000.00,
      target_date: Date.today + 2.months
    )

    result = calculator.calculate

    # Check first month
    first = result[:monthly_breakdown][0]
    assert_equal 100.00, first[:contribution]
    # (1000 + 100) * 0.01 = 11
    assert_in_delta 11.00, first[:interest], 0.01

    # Check second month
    second = result[:monthly_breakdown][1]
    assert_equal 100.00, second[:contribution]
    # Previous balance was 1111, plus 100 contribution = 1211 * 0.01 = 12.11
    assert_in_delta 12.11, second[:interest], 0.01
  end

  test "handles decimal precision correctly" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 33.33,
      annual_return_rate: 5.55
    )

    calculator = ProjectionCalculator.new(
      projection: projection,
      current_balance: 123.45,
      target_date: Date.today + 6.months
    )

    result = calculator.calculate

    # Should not raise errors and should return rounded values
    assert_kind_of BigDecimal, result[:final_balance]
    assert_equal 2, result[:final_balance].to_s.split('.').last.length
  end
end
```

**Step 4: Run service tests**

Run:
```bash
bin/rails test test/services/projection_calculator_test.rb
```

Expected: All tests pass (11 tests)

**Step 5: Commit**

Run:
```bash
git add app/services/ test/services/
git commit -m "Add ProjectionCalculator service with comprehensive tests"
```

---

## Task 3: Create ProjectionsController

**Files:**
- Create: `app/controllers/projections_controller.rb`
- Create: `test/controllers/projections_controller_test.rb`
- Modify: `config/routes.rb:14` (add projection resource)

**Step 1: Add route**

Modify `config/routes.rb:13-15`:

```ruby
  # Savings account management
  resources :accounts do
    resources :adjustments, only: [:new, :create]
    resource :projection, only: [:edit, :update]
  end
```

**Step 2: Write ProjectionsController**

Create `app/controllers/projections_controller.rb`:

```ruby
class ProjectionsController < ApplicationController
  before_action :set_account

  def edit
    @projection = @account.projection || @account.build_projection
  end

  def update
    @projection = @account.projection || @account.build_projection

    if @projection.update(projection_params)
      redirect_to @account, notice: "Projection settings saved."
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

**Step 3: Write controller tests**

Create `test/controllers/projections_controller_test.rb`:

```ruby
require "test_helper"

class ProjectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
  end

  test "should get edit when no projection exists" do
    get edit_account_projection_url(@account)
    assert_response :success
    assert_select "form"
  end

  test "should get edit when projection exists" do
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    get edit_account_projection_url(@account)
    assert_response :success
    assert_select "form"
    assert_select "input[value='500.0']"
    assert_select "input[value='5.0']"
  end

  test "should create projection with valid params" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 600,
          annual_return_rate: 7.0
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_equal "Projection settings saved.", flash[:notice]

    @account.reload
    assert_equal 600.0, @account.projection.monthly_contribution.to_f
    assert_equal 7.0, @account.projection.annual_return_rate.to_f
  end

  test "should update existing projection" do
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 800,
          annual_return_rate: 6.5
        }
      }
    end

    assert_redirected_to account_url(@account)

    @projection.reload
    assert_equal 800.0, @projection.monthly_contribution.to_f
    assert_equal 6.5, @projection.annual_return_rate.to_f
  end

  test "should not create projection with negative contribution" do
    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: -100,
          annual_return_rate: 5.0
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "should not create projection without annual_return_rate" do
    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 500,
          annual_return_rate: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should allow zero monthly_contribution" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 0,
          annual_return_rate: 5.0
        }
      }
    end

    assert_redirected_to account_url(@account)
  end

  test "should allow negative annual_return_rate" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 500,
          annual_return_rate: -2.0
        }
      }
    end

    assert_redirected_to account_url(@account)
  end
end
```

**Step 4: Run controller tests**

Run:
```bash
bin/rails test test/controllers/projections_controller_test.rb
```

Expected: All tests pass (8 tests)

**Step 5: Commit**

Run:
```bash
git add app/controllers/projections_controller.rb test/controllers/projections_controller_test.rb config/routes.rb
git commit -m "Add ProjectionsController with edit and update actions"
```

---

## Task 4: Create Projection Edit View

**Files:**
- Create: `app/views/projections/edit.html.erb`

**Step 1: Create projections views directory**

Run:
```bash
mkdir -p app/views/projections
```

**Step 2: Write projection edit form**

Create `app/views/projections/edit.html.erb`:

```erb
<div class="max-w-2xl mx-auto">
  <h1 class="text-3xl font-bold mb-6">Projection Settings</h1>

  <div class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
    <%= form_with(model: @projection, url: account_projection_path(@account), method: :patch, local: true) do |form| %>
      <% if @projection.errors.any? %>
        <div id="error_explanation" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
          <h2 class="font-bold mb-2"><%= pluralize(@projection.errors.count, "error") %> prohibited this projection from being saved:</h2>
          <ul class="list-disc list-inside">
            <% @projection.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <div class="mb-4">
        <%= form.label :monthly_contribution, "Expected Monthly Contribution", class: "block text-gray-700 text-sm font-bold mb-2" %>
        <%= form.number_field :monthly_contribution, step: 0.01, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" %>
        <p class="text-gray-600 text-xs mt-1">Amount you plan to deposit each month</p>
      </div>

      <div class="mb-6">
        <%= form.label :annual_return_rate, "Expected Annual Return Rate (%)", class: "block text-gray-700 text-sm font-bold mb-2" %>
        <%= form.number_field :annual_return_rate, step: 0.01, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" %>
        <p class="text-gray-600 text-xs mt-1">Enter as percentage (e.g., 5.0 for 5% annual returns)</p>
      </div>

      <div class="flex items-center justify-between">
        <%= form.submit "Save Projection Settings", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" %>
        <%= link_to "Cancel", @account, class: "text-gray-600 hover:text-gray-800" %>
      </div>
    <% end %>
  </div>
</div>
```

**Step 3: Run controller tests to verify view renders**

Run:
```bash
bin/rails test test/controllers/projections_controller_test.rb
```

Expected: All tests still pass (view renders correctly)

**Step 4: Commit**

Run:
```bash
git add app/views/projections/
git commit -m "Add projection edit form view"
```

---

## Task 5: Update AccountsController for Projection Calculation

**Files:**
- Modify: `app/controllers/accounts_controller.rb:8-10`
- Create: `test/controllers/accounts_controller_projection_test.rb`

**Step 1: Write failing test**

Create `test/controllers/accounts_controller_projection_test.rb`:

```ruby
require "test_helper"

class AccountsControllerProjectionTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @account.update!(balance: 10000.00)
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 6.0
    )
  end

  test "show page without target_date does not calculate projection" do
    get account_url(@account)
    assert_response :success
    assert_nil assigns(:projection_result)
  end

  test "show page with target_date calculates projection" do
    target_date = Date.today + 12.months

    get account_url(@account), params: { target_date: target_date.to_s }
    assert_response :success

    result = assigns(:projection_result)
    assert_not_nil result
    assert result[:final_balance] > 10000.00
    assert_not_empty result[:monthly_breakdown]
  end

  test "show page without projection does not calculate even with target_date" do
    @account.projection.destroy

    get account_url(@account), params: { target_date: (Date.today + 1.year).to_s }
    assert_response :success
    assert_nil assigns(:projection_result)
  end

  test "show page with invalid target_date handles gracefully" do
    get account_url(@account), params: { target_date: "invalid" }
    assert_response :success
    # Should not crash, either shows error or ignores
  end
end
```

**Step 2: Run test to verify it fails**

Run:
```bash
bin/rails test test/controllers/accounts_controller_projection_test.rb
```

Expected: Tests fail because @projection_result is not being calculated

**Step 3: Update AccountsController show action**

Modify `app/controllers/accounts_controller.rb:8-10`:

```ruby
  def show
    @adjustments = @account.adjustments.order(adjusted_at: :desc)

    # Calculate projection if parameters present
    if @account.projection && params[:target_date].present?
      begin
        target_date = Date.parse(params[:target_date])
        calculator = ProjectionCalculator.new(
          projection: @account.projection,
          current_balance: @account.balance,
          target_date: target_date
        )
        @projection_result = calculator.calculate
      rescue Date::Error
        # Invalid date format - ignore and don't calculate
        @projection_result = nil
      end
    end
  end
```

**Step 4: Run tests to verify they pass**

Run:
```bash
bin/rails test test/controllers/accounts_controller_projection_test.rb
```

Expected: All tests pass (4 tests)

**Step 5: Run all controller tests to ensure nothing broke**

Run:
```bash
bin/rails test test/controllers/
```

Expected: All controller tests pass

**Step 6: Commit**

Run:
```bash
git add app/controllers/accounts_controller.rb test/controllers/accounts_controller_projection_test.rb
git commit -m "Add projection calculation to AccountsController show action"
```

---

## Task 6: Update Account Show View with Projection UI

**Files:**
- Modify: `app/views/accounts/show.html.erb`

**Step 1: Read current account show view**

Run:
```bash
cat app/views/accounts/show.html.erb
```

**Step 2: Add projection sections to account show view**

Modify `app/views/accounts/show.html.erb` to add projection sections after the account header but before the adjustments section:

```erb
<!-- existing account header stays -->

<!-- Projection Settings Section -->
<div class="bg-white shadow-md rounded px-8 pt-6 pb-6 mb-6">
  <h2 class="text-2xl font-bold mb-4">Future Projections</h2>

  <% if @account.projection %>
    <div class="mb-4">
      <p class="text-gray-700">
        <span class="font-semibold">Monthly Contribution:</span>
        <%= number_to_currency(@account.projection.monthly_contribution) %>
      </p>
      <p class="text-gray-700">
        <span class="font-semibold">Expected Annual Return:</span>
        <%= number_to_percentage(@account.projection.annual_return_rate, precision: 2) %>
      </p>
    </div>
    <%= link_to "Edit Projection Settings", edit_account_projection_path(@account), class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
  <% else %>
    <p class="text-gray-600 mb-4">Set up projection parameters to see future balance estimates.</p>
    <%= link_to "Set Up Projection", edit_account_projection_path(@account), class: "bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded" %>
  <% end %>
</div>

<!-- Projection Calculator Section -->
<% if @account.projection %>
  <div class="bg-white shadow-md rounded px-8 pt-6 pb-6 mb-6">
    <h2 class="text-2xl font-bold mb-4">Calculate Future Balance</h2>

    <%= form_with url: account_path(@account), method: :get, local: true do |form| %>
      <div class="mb-4">
        <%= form.label :target_date, "Project to Date:", class: "block text-gray-700 text-sm font-bold mb-2" %>
        <%= form.date_field :target_date, value: params[:target_date], class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" %>
      </div>
      <%= form.submit "Calculate Projection", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
    <% end %>

    <% if @projection_result %>
      <div class="mt-6">
        <div class="bg-green-50 border-l-4 border-green-500 p-4 mb-4">
          <p class="text-2xl font-bold text-green-800">
            Projected Balance: <%= number_to_currency(@projection_result[:final_balance]) %>
          </p>
          <p class="text-sm text-green-700">as of <%= params[:target_date] %></p>
        </div>

        <h3 class="text-xl font-bold mb-3">Monthly Breakdown</h3>
        <div class="overflow-x-auto max-h-96 overflow-y-auto">
          <table class="min-w-full bg-white border">
            <thead class="bg-gray-100 sticky top-0">
              <tr>
                <th class="px-4 py-2 border text-left">Date</th>
                <th class="px-4 py-2 border text-right">Contribution</th>
                <th class="px-4 py-2 border text-right">Interest Earned</th>
                <th class="px-4 py-2 border text-right">Balance</th>
              </tr>
            </thead>
            <tbody>
              <% @projection_result[:monthly_breakdown].each do |month| %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-2 border"><%= month[:date].strftime("%b %Y") %></td>
                  <td class="px-4 py-2 border text-right"><%= number_to_currency(month[:contribution]) %></td>
                  <td class="px-4 py-2 border text-right"><%= number_to_currency(month[:interest]) %></td>
                  <td class="px-4 py-2 border text-right font-semibold"><%= number_to_currency(month[:balance]) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    <% end %>
  </div>
<% end %>

<!-- existing adjustments history section stays -->
```

**Step 3: Verify view by running system (or manual browser test)**

Run:
```bash
bin/rails server
```

Then manually test:
1. Visit an account page
2. Click "Set Up Projection"
3. Fill in values and save
4. Return to account page and verify settings displayed
5. Enter a target date and click Calculate
6. Verify results displayed

**Step 4: Commit**

Run:
```bash
git add app/views/accounts/show.html.erb
git commit -m "Add projection UI to account show page"
```

---

## Task 7: Write System Tests for End-to-End Workflows

**Files:**
- Create: `test/system/projections_test.rb`

**Step 1: Write comprehensive system tests**

Create `test/system/projections_test.rb`:

```ruby
require "application_system_test_case"

class ProjectionsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
    @account.update!(balance: 5000.00)
  end

  test "setting up projection for first time" do
    visit account_url(@account)

    # Should show "Set Up Projection" button
    assert_text "Set up projection parameters"
    click_on "Set Up Projection"

    # Fill in projection form
    fill_in "Expected Monthly Contribution", with: 500
    fill_in "Expected Annual Return Rate (%)", with: 5.0
    click_on "Save Projection Settings"

    # Should redirect to account page with settings displayed
    assert_text "Projection settings saved"
    assert_text "Monthly Contribution: $500.00"
    assert_text "Expected Annual Return: 5.00%"
  end

  test "calculating projection with valid parameters" do
    # Set up projection first
    Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 6.0
    )

    visit account_url(@account)

    # Should show projection settings
    assert_text "Monthly Contribution: $500.00"

    # Calculate projection
    target_date = 5.years.from_now.to_date
    fill_in "Project to Date:", with: target_date.to_s
    click_on "Calculate Projection"

    # Should show results
    assert_text "Projected Balance:"
    assert_text "Monthly Breakdown"

    # Should show monthly table
    within "table" do
      assert_selector "tr", minimum: 60 # At least 5 years of months
    end
  end

  test "editing existing projection" do
    Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    visit account_url(@account)
    click_on "Edit Projection Settings"

    # Should show current values
    assert_field "Expected Monthly Contribution", with: "500.0"
    assert_field "Expected Annual Return Rate (%)", with: "5.0"

    # Update values
    fill_in "Expected Monthly Contribution", with: 750
    fill_in "Expected Annual Return Rate (%)", with: 7.0
    click_on "Save Projection Settings"

    # Should show updated values
    assert_text "Monthly Contribution: $750.00"
    assert_text "Expected Annual Return: 7.00%"
  end

  test "validation error for negative contribution" do
    visit account_url(@account)
    click_on "Set Up Projection"

    fill_in "Expected Monthly Contribution", with: -100
    fill_in "Expected Annual Return Rate (%)", with: 5.0
    click_on "Save Projection Settings"

    # Should show error
    assert_text "prohibited this projection from being saved"
    assert_text "Monthly contribution must be greater than or equal to 0"
  end

  test "validation error for missing return rate" do
    visit account_url(@account)
    click_on "Set Up Projection"

    fill_in "Expected Monthly Contribution", with: 500
    fill_in "Expected Annual Return Rate (%)", with: ""
    click_on "Save Projection Settings"

    # Should show error
    assert_text "prohibited this projection from being saved"
  end

  test "zero monthly contribution is valid" do
    visit account_url(@account)
    click_on "Set Up Projection"

    fill_in "Expected Monthly Contribution", with: 0
    fill_in "Expected Annual Return Rate (%)", with: 5.0
    click_on "Save Projection Settings"

    assert_text "Projection settings saved"
    assert_text "Monthly Contribution: $0.00"
  end

  test "recalculating after changing projection parameters" do
    Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    visit account_url(@account)

    # Calculate initial projection
    target_date = 10.years.from_now.to_date
    fill_in "Project to Date:", with: target_date.to_s
    click_on "Calculate Projection"

    # Note the result
    initial_result = find(".bg-green-50").text

    # Edit projection to increase contribution
    click_on "Edit Projection Settings"
    fill_in "Expected Monthly Contribution", with: 1000
    click_on "Save Projection Settings"

    # Recalculate with same target date
    fill_in "Project to Date:", with: target_date.to_s
    click_on "Calculate Projection"

    # Result should be different (higher)
    new_result = find(".bg-green-50").text
    assert_not_equal initial_result, new_result
  end

  test "projection display shows formatted currency and percentages" do
    Projection.create!(
      account: @account,
      monthly_contribution: 1234.56,
      annual_return_rate: 7.89
    )

    visit account_url(@account)

    # Should format currency with dollar sign and cents
    assert_text "Monthly Contribution: $1,234.56"

    # Should format percentage
    assert_text "Expected Annual Return: 7.89%"
  end

  test "long-term projection displays many months" do
    Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 7.0
    )

    visit account_url(@account)

    # Calculate 30-year projection
    target_date = 30.years.from_now.to_date
    fill_in "Project to Date:", with: target_date.to_s
    click_on "Calculate Projection"

    # Should show substantial growth
    assert_text "Projected Balance:"

    # Table should be scrollable and show many rows
    within "table tbody" do
      assert_selector "tr", minimum: 360 # At least 30 years of months
    end
  end
end
```

**Step 2: Run system tests**

Run:
```bash
bin/rails test:system test/system/projections_test.rb
```

Expected: All system tests pass (10 tests)

**Step 3: Commit**

Run:
```bash
git add test/system/projections_test.rb
git commit -m "Add comprehensive system tests for projections feature"
```

---

## Task 8: Run Full Test Suite and Verify

**Files:**
- None (verification step)

**Step 1: Run all tests**

Run:
```bash
bin/rails test
```

Expected: All tests pass (model + service + controller + system tests)

**Step 2: Check test count**

Expected total should be approximately:
- 9 projection model tests
- 11 projection calculator service tests
- 8 projections controller tests
- 4 accounts controller projection tests
- 10 projection system tests
- Plus existing tests (17 from baseline)

Total: ~59 tests, 0 failures

**Step 3: Run system tests separately to verify UI**

Run:
```bash
bin/rails test:system
```

Expected: All system tests pass with browser automation

**Step 4: Verify no regressions**

Run:
```bash
bin/rails test:models
bin/rails test:controllers
```

Expected: All existing tests still pass

**Step 5: Commit if any fixes were needed**

If you had to fix anything:
```bash
git add .
git commit -m "Fix any test failures or edge cases"
```

---

## Task 9: Manual Testing and Final Verification

**Files:**
- None (manual verification)

**Step 1: Start Rails server**

Run:
```bash
bin/rails server
```

**Step 2: Manual test workflow**

1. Visit http://localhost:3000
2. Create a new account with initial balance of $10,000
3. Visit the account show page
4. Click "Set Up Projection"
5. Enter monthly contribution: $500
6. Enter annual return rate: 6.0%
7. Click Save
8. Verify you're redirected to account page
9. Verify projection settings displayed correctly
10. Enter target date: 10 years from today
11. Click "Calculate Projection"
12. Verify projected balance is displayed prominently
13. Verify monthly breakdown table appears
14. Scroll through table to verify data looks correct
15. Click "Edit Projection Settings"
16. Change monthly contribution to $1000
17. Save and recalculate
18. Verify projected balance increased

**Step 3: Test edge cases manually**

1. Try creating projection with $0 monthly contribution
2. Try creating projection with negative annual return (-2%)
3. Try very long projection (40 years)
4. Try very short projection (1 month)
5. Try editing and deleting accounts with projections

**Step 4: Verify all features work**

- [ ] Can create projection
- [ ] Can edit projection
- [ ] Can calculate projection
- [ ] Monthly breakdown displays correctly
- [ ] Validation errors show for invalid input
- [ ] Currency formatting looks good
- [ ] Percentage formatting looks good
- [ ] Table is scrollable for long projections
- [ ] Can navigate between account and projection pages

---

## Task 10: Final Commit and Verification

**Files:**
- All modified and created files

**Step 1: Check git status**

Run:
```bash
git status
```

Expected: Working directory clean (all changes committed)

**Step 2: Review commit history**

Run:
```bash
git log --oneline
```

Expected: Should see ~9-10 commits for this feature:
1. Add Projection model with validations and tests
2. Add ProjectionCalculator service with comprehensive tests
3. Add ProjectionsController with edit and update actions
4. Add projection edit form view
5. Add projection calculation to AccountsController show action
6. Add projection UI to account show page
7. Add comprehensive system tests for projections feature
8. (Any fix commits if needed)

**Step 3: Run full test suite one final time**

Run:
```bash
bin/rails test
bin/rails test:system
```

Expected: All tests pass

**Step 4: Verify feature completeness**

Check that all requirements from design doc are met:
- [x] Store projection parameters per account (monthly contribution, annual return rate)
- [x] Calculate projected balance to user-specified target date
- [x] Use compound interest calculation
- [x] Display final projected balance prominently
- [x] Show detailed monthly breakdown
- [x] Allow editing projection parameters
- [x] Service object pattern for calculations
- [x] Integrated into account show page
- [x] Comprehensive test coverage

**Step 5: Push to remote (when ready)**

When ready to merge/create PR:
```bash
git push -u origin feature/savings-projections
```

---

## Summary

This implementation adds a complete projection feature to the savings account application:

- **Database**: Projection model with proper validations and associations
- **Business Logic**: ProjectionCalculator service for compound interest math
- **Controllers**: ProjectionsController for CRUD + AccountsController updates for calculation
- **Views**: Projection edit form + integrated calculator on account show page
- **Tests**: 40+ new tests covering models, services, controllers, and system workflows

**Key Principles Applied:**
- **TDD**: Tests written before or alongside implementation
- **DRY**: Service object reused for all calculations
- **YAGNI**: No over-engineering (one projection per account, no premature optimization)
- **Frequent commits**: Each task is one logical commit

**Total Time Estimate:** 3-4 hours for experienced Rails developer
