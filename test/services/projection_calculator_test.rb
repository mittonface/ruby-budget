require "test_helper"

class ProjectionCalculatorTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )
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
    assert_operator result[:final_balance], :<, 18000.00

    # Verify it's around the expected compound value (with wider delta for calculation variations)
    assert_in_delta 17400.00, result[:final_balance], 100.00
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
    assert_equal 2, result[:final_balance].to_s.split(".").last.length
  end
end
