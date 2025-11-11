require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  test "creating a new account and adding adjustments" do
    visit root_path

    # Create a new account
    click_on "New Account"
    fill_in "Account Name", with: "Emergency Fund"
    fill_in "Initial Balance", with: "1000"
    fill_in "Opened Date", with: Date.current.to_s
    click_on "Create Account"

    assert_text "Emergency Fund"
    assert_text "$1,000.00"

    # Add a positive adjustment (deposit)
    click_on "Add Adjustment"
    fill_in "Amount", with: "500"
    fill_in "Description", with: "Paycheck deposit"
    click_on "Add Adjustment"

    assert_text "$1,500.00" # New balance
    assert_text "Paycheck deposit"
    assert_text "+$500.00"

    # Add a negative adjustment (withdrawal)
    click_on "Add Adjustment"
    fill_in "Amount", with: "-200"
    fill_in "Description", with: "Emergency car repair"
    click_on "Add Adjustment"

    assert_text "$1,300.00" # New balance after withdrawal
    assert_text "Emergency car repair"
    assert_text "-$200.00"

    # Verify running balance is shown (case insensitive)
    assert_text /running balance/i
  end

  test "editing an account" do
    account = Account.create!(
      name: "Test Account",
      balance: 500,
      initial_balance: 500,
      opened_at: Date.current
    )

    visit account_path(account)
    click_on "Edit Account"

    fill_in "Account Name", with: "Updated Account Name"
    click_on "Update Account"

    assert_text "Updated Account Name"
  end

  test "deleting an account" do
    account = Account.create!(
      name: "Account to Delete",
      balance: 100,
      initial_balance: 100,
      opened_at: Date.current
    )

    visit account_path(account)
    accept_confirm do
      click_on "Delete Account"
    end

    assert_current_path accounts_path
    assert_no_text "Account to Delete"
  end

  test "viewing empty accounts list" do
    # Clear all fixtures for this test
    Account.delete_all

    visit root_path

    assert_text "No savings accounts yet."
    assert_text "No debts yet."
  end

  test "account shows initial balance and opened date" do
    account = Account.create!(
      name: "Vacation Fund",
      balance: 2500,
      initial_balance: 2500,
      opened_at: Date.new(2024, 1, 15)
    )

    visit account_path(account)

    assert_text "Vacation Fund"
    assert_text "$2,500.00"
    assert_text "Initial Balance: $2,500.00"
    assert_text "January 15, 2024"
  end

  test "adjustment history shows in correct order" do
    account = Account.create!(
      name: "Test Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    # Create adjustments in specific order
    account.adjustments.create!(amount: 100, adjusted_at: 3.days.ago, description: "First")
    account.adjustments.create!(amount: 200, adjusted_at: 2.days.ago, description: "Second")
    account.adjustments.create!(amount: 300, adjusted_at: 1.day.ago, description: "Third")

    visit account_path(account)

    # Verify they appear in reverse chronological order
    page_text = page.text
    assert page_text.index("Third") < page_text.index("Second")
    assert page_text.index("Second") < page_text.index("First")
  end

  test "cannot create account without name" do
    visit new_account_path

    fill_in "Initial Balance", with: "1000"
    fill_in "Opened Date", with: Date.current.to_s
    click_on "Create Account"

    assert_text "Name can't be blank"
  end

  test "cannot create adjustment with zero amount" do
    account = Account.create!(
      name: "Test Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )

    visit new_account_adjustment_path(account)

    fill_in "Amount", with: "0"
    click_on "Add Adjustment"

    assert_text "Amount must be other than 0"
  end
end
