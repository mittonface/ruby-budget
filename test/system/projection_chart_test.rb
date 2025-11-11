require "application_system_test_case"

class ProjectionChartTest < ApplicationSystemTestCase
  test "displays chart when projection exists with target date" do
    account = Account.create!(
      name: "Test Savings Account",
      balance: 5000.00,
      initial_balance: 5000.00,
      opened_at: Date.current
    )
    projection = Projection.create!(
      account: account,
      monthly_contribution: 500,
      annual_return_rate: 6.0,
      target_date: 1.year.from_now
    )

    visit account_path(account)

    # Chart container should exist
    assert_selector "#projection-chart", visible: true
  end

  test "does not display chart when no projection exists" do
    account = Account.create!(
      name: "Test Checking Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Date.current
    )

    visit account_path(account)

    # Chart container should not exist
    assert_no_selector "#projection-chart"
  end
end
