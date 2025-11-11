require "application_system_test_case"

class SetBalanceTest < ApplicationSystemTestCase
  test "toggling between add adjustment and set balance modes" do
    account = Account.create!(
      name: "Test Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    visit new_account_adjustment_path(account)

    # Default mode should be "Add Adjustment"
    assert find("input#mode_add_adjustment").checked?
    assert_selector "input#adjustment_amount", visible: true
    assert_selector "input#adjustment_new_balance", visible: false

    # Switch to "Set Balance" mode
    choose "Set Balance"
    assert_selector "input#adjustment_amount", visible: false
    assert_selector "input#adjustment_new_balance", visible: true

    # Switch back to "Add Adjustment"
    choose "Add Adjustment"
    assert_selector "input#adjustment_amount", visible: true
    assert_selector "input#adjustment_new_balance", visible: false
  end

  test "setting balance calculates adjustment automatically" do
    account = Account.create!(
      name: "Savings Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    visit new_account_adjustment_path(account)

    # Switch to Set Balance mode
    choose "Set Balance"

    # Set new balance
    fill_in "New Balance", with: "1750"
    fill_in "Description", with: "Corrected balance"
    click_on "Add Adjustment"

    # Verify adjustment was created correctly
    assert_text "$1,750.00" # New balance
    assert_text "Corrected balance"
    assert_text "+$750.00" # Calculated adjustment
  end

  test "setting balance to same value shows validation error" do
    account = Account.create!(
      name: "Savings Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    visit new_account_adjustment_path(account)

    # Switch to Set Balance mode
    choose "Set Balance"

    # Set balance to current value (should fail)
    fill_in "New Balance", with: "1000"
    click_on "Add Adjustment"

    # Should show validation error
    assert_text "Amount must be other than 0"
  end

  test "setting balance lower than current creates negative adjustment" do
    account = Account.create!(
      name: "Savings Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    visit new_account_adjustment_path(account)

    # Switch to Set Balance mode
    choose "Set Balance"

    # Set lower balance
    fill_in "New Balance", with: "700"
    fill_in "Description", with: "Withdrawal correction"
    click_on "Add Adjustment"

    # Verify negative adjustment was created
    assert_text "$700.00" # New balance
    assert_text "Withdrawal correction"
    assert_text "-$300.00" # Calculated negative adjustment
  end
end
