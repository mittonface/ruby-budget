class MortgageCalculator
  attr_reader :mortgage

  def initialize(mortgage)
    @mortgage = mortgage
  end

  # Calculate required monthly payment using amortization formula
  # M = P * [r(1+r)^n] / [(1+r)^n - 1]
  # where P = principal, r = monthly rate, n = number of payments
  def calculate_monthly_payment
    principal = mortgage.principal
    annual_rate = mortgage.interest_rate
    term_years = mortgage.term_years

    # Handle zero interest rate edge case
    if annual_rate == 0
      return principal / (term_years * 12.0)
    end

    monthly_rate = (annual_rate / 12.0) / 100.0
    num_payments = term_years * 12

    # Amortization formula
    numerator = monthly_rate * ((1 + monthly_rate) ** num_payments)
    denominator = ((1 + monthly_rate) ** num_payments) - 1

    principal * (numerator / denominator)
  end
end
