require "application_system_test_case"

class ProjectionsTest < ApplicationSystemTestCase
  setup do
    @account = Account.create!(
      name: "Test Savings Account",
      balance: 5000.00,
      initial_balance: 5000.00,
      opened_at: Date.current
    )
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

    # Calculate projection - using page.execute_script to bypass browser validation issues
    target_date = 5.years.from_now.to_date
    page.execute_script("document.querySelector('input[type=\"date\"]').value = '#{target_date}'")
    click_on "Calculate Projection"

    # Should show results
    assert_text "Projected Balance:"
    assert_text "Monthly Breakdown"

    # Should show monthly table with contribution and interest columns
    assert_text "Contribution"
    assert_text "Interest Earned"

    # Should show monthly table
    within "table tbody" do
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
    page.execute_script("document.querySelector('input[type=\"date\"]').value = '#{target_date}'")
    click_on "Calculate Projection"

    # Note the result
    initial_result = find(".bg-green-50").text

    # Edit projection to increase contribution
    click_on "Edit Projection Settings"
    fill_in "Expected Monthly Contribution", with: 1000
    click_on "Save Projection Settings"

    # Should now be back on account page
    assert_text "Monthly Contribution: $1,000.00"

    # Recalculate with same target date - need to wait for page to fully load
    page.execute_script("document.querySelector('input[type=\"date\"]').value = '#{target_date}'")
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
    page.execute_script("document.querySelector('input[type=\"date\"]').value = '#{target_date}'")
    click_on "Calculate Projection"

    # Should show substantial growth
    assert_text "Projected Balance:"

    # Table should be scrollable and show many rows
    within "table tbody" do
      assert_selector "tr", minimum: 360 # At least 30 years of months
    end
  end

  test "account without projection shows setup prompt" do
    # Create a fresh account without projection
    account_without_projection = Account.create!(
      name: "New Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Date.current
    )

    visit account_url(account_without_projection)

    # Should show setup prompt
    assert_text "Set up projection parameters to see future balance estimates"
    assert_selector "a", text: "Set Up Projection"

    # Should NOT show calculator section
    assert_no_text "Calculate Future Balance"
  end
end
