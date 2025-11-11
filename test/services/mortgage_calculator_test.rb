require "test_helper"

class MortgageCalculatorTest < ActiveSupport::TestCase
  def setup
    @mortgage = Mortgage.new(
      name: "Test Mortgage",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: 300000.0,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )
  end

  test "calculates monthly payment correctly" do
    calculator = MortgageCalculator.new(@mortgage)
    monthly_payment = calculator.calculate_monthly_payment

    # Known value: $300k at 3.5% for 30 years = ~$1,347.13/month
    assert_in_delta 1347.13, monthly_payment, 0.01
  end

  test "calculates monthly payment for zero interest rate" do
    @mortgage.interest_rate = 0.0
    calculator = MortgageCalculator.new(@mortgage)
    monthly_payment = calculator.calculate_monthly_payment

    # No interest: just principal / months
    expected = 300000.0 / (30 * 12)
    assert_in_delta expected, monthly_payment, 0.01
  end

  test "calculates monthly payment for different loan amounts" do
    @mortgage.principal = 500000.0
    @mortgage.balance = 500000.0
    @mortgage.interest_rate = 4.0
    @mortgage.term_years = 15

    calculator = MortgageCalculator.new(@mortgage)
    monthly_payment = calculator.calculate_monthly_payment

    # Known value: $500k at 4% for 15 years = ~$3,698.44/month
    assert_in_delta 3698.44, monthly_payment, 0.01
  end

  test "calculates payment breakdown with principal and interest portions" do
    calculator = MortgageCalculator.new(@mortgage)
    breakdown = calculator.calculate_payment_breakdown

    monthly_payment = calculator.calculate_monthly_payment

    # First payment: mostly interest
    assert_in_delta 875.0, breakdown[:interest_portion], 1.0  # ~$875 interest
    assert_in_delta 472.13, breakdown[:principal_portion], 1.0  # ~$472 principal
    assert_in_delta monthly_payment, breakdown[:interest_portion] + breakdown[:principal_portion], 0.01
  end

  test "calculates payment breakdown using current balance" do
    # Simulate mortgage with $200k remaining
    @mortgage.balance = 200000.0
    calculator = MortgageCalculator.new(@mortgage)
    breakdown = calculator.calculate_payment_breakdown

    # Interest on $200k at 3.5% annual = $200k * (3.5/12/100) = $583.33
    assert_in_delta 583.33, breakdown[:interest_portion], 0.01

    monthly_payment = calculator.calculate_monthly_payment
    expected_principal = monthly_payment - breakdown[:interest_portion]
    assert_in_delta expected_principal, breakdown[:principal_portion], 0.01
  end

  test "generates amortization schedule for specified months" do
    calculator = MortgageCalculator.new(@mortgage)
    schedule = calculator.generate_amortization_schedule(12)

    assert_equal 12, schedule.length

    # First month
    first = schedule[0]
    assert_equal 1, first[:month]
    assert_in_delta 300000.0, first[:starting_balance], 0.01
    assert_in_delta 875.0, first[:interest_payment], 1.0
    assert_in_delta 472.13, first[:principal_payment], 1.0
    assert first[:ending_balance] < first[:starting_balance]

    # Last month should have lower balance
    last = schedule[11]
    assert_equal 12, last[:month]
    assert last[:ending_balance] < first[:ending_balance]

    # Verify balance decreases each month
    schedule.each_with_index do |payment, index|
      if index > 0
        assert payment[:starting_balance] < schedule[index - 1][:starting_balance]
      end
    end
  end

  test "generates schedule considering extra payments from projection" do
    # Add projection with extra monthly payment
    @mortgage.build_projection(monthly_contribution: 500.0)

    calculator = MortgageCalculator.new(@mortgage)
    schedule_with_extra = calculator.generate_amortization_schedule(12)

    # Without extra payments
    @mortgage.projection.monthly_contribution = 0
    schedule_normal = calculator.generate_amortization_schedule(12)

    # Extra payments should reduce balance faster
    assert schedule_with_extra[11][:ending_balance] < schedule_normal[11][:ending_balance]
  end
end
