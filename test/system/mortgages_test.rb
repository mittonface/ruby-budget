require "application_system_test_case"

class MortgagesTest < ApplicationSystemTestCase
  test "creating a mortgage" do
    visit accounts_url
    click_on "New Account"

    # Select Mortgage type
    choose "Mortgage"

    # Wait for fields to be visible after choosing mortgage
    assert_selector "input[name='account[principal]']", visible: true

    # Fill in common fields
    fill_in "Account Name", with: "Home Loan"

    # Use execute_script to set date fields properly
    page.execute_script("document.querySelector('input[name=\"account[opened_at]\"]').value = '#{Date.current.strftime("%Y-%m-%d")}'")

    # Fill in mortgage details
    fill_in "Loan Amount", with: "300000"
    fill_in "Interest Rate (%)", with: "3.5"
    fill_in "Loan Term (years)", with: "30"

    # Use execute_script to set loan start date
    page.execute_script("document.querySelector('input[name=\"account[loan_start_date]\"]').value = '#{Date.current.strftime("%Y-%m-%d")}'")

    # Submit form using the submit button
    find("input[type='submit']").click

    # Should be on account show page
    assert_current_path(/\/accounts\/\d+/)
    assert_text "Home Loan"
    assert_text "$300,000.00"
    assert_text "3.5%"
  end

  test "mortgage shows on index in debts section" do
    mortgage = Mortgage.create!(
      name: "Test Mortgage",
      balance: 250000,
      initial_balance: 250000,
      opened_at: Date.current,
      principal: 250000,
      interest_rate: 4.0,
      term_years: 15,
      loan_start_date: Date.current
    )

    visit accounts_url

    # Check that it appears in the Debts section
    assert_text "DEBTS"
    assert_text "Test Mortgage"
    assert_text "$250,000.00"
    assert_text "4.0%"
  end

  test "recording a mortgage payment" do
    mortgage = Mortgage.create!(
      name: "Home Loan",
      balance: 300000,
      initial_balance: 300000,
      opened_at: Date.current,
      principal: 300000,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    visit account_url(mortgage)
    click_on "Record Payment"

    fill_in "Amount", with: "-1347.13"
    # Date & Time is a datetime-local field, format: YYYY-MM-DDTHH:MM
    fill_in "Date & Time", with: Time.current.strftime("%Y-%m-%dT%H:%M")

    click_on "Add Adjustment"

    # Should redirect to account show page
    assert_current_path account_path(mortgage)

    # Balance should be reduced
    mortgage.reload
    assert mortgage.balance < 300000
    assert_in_delta 298652.87, mortgage.balance, 1.0
  end

  test "net worth calculation includes mortgages" do
    # Clear fixtures for this test
    Account.delete_all

    SavingsAccount.create!(
      name: "Savings",
      balance: 50000,
      initial_balance: 50000,
      opened_at: Date.current
    )

    Mortgage.create!(
      name: "Home Loan",
      balance: 300000,
      initial_balance: 300000,
      opened_at: Date.current,
      principal: 300000,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    visit accounts_url

    # Net worth = 50000 - 300000 = -250000
    assert_text "-$250,000.00"
    # Net worth is displayed, totals breakdown may not be visible on index
  end

  test "mortgage show page displays amortization" do
    mortgage = Mortgage.create!(
      name: "Home Loan",
      balance: 300000,
      initial_balance: 300000,
      opened_at: Date.current,
      principal: 300000,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    visit account_url(mortgage)

    assert_text "Loan Details"
    assert_text "Current Status"
    assert_text "Amortization Schedule"
    assert_text "Monthly Payment"

    # Check payment breakdown is shown
    assert_text "Principal:"
    assert_text "Interest:"
  end
end
