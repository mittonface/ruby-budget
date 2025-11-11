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
end
