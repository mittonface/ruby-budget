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

  # Calculate how much of next payment goes to principal vs interest
  # Uses current balance to determine interest portion
  def calculate_payment_breakdown
    current_balance = mortgage.balance
    annual_rate = mortgage.interest_rate
    monthly_rate = (annual_rate / 12.0) / 100.0

    # Interest portion based on current balance
    interest_portion = current_balance * monthly_rate

    # Principal portion is remainder of payment
    monthly_payment = calculate_monthly_payment
    principal_portion = monthly_payment - interest_portion

    {
      interest_portion: interest_portion,
      principal_portion: principal_portion,
      total_payment: monthly_payment
    }
  end

  # Generate amortization schedule showing balance reduction over time
  # Includes extra payments from projection if present
  def generate_amortization_schedule(num_months)
    monthly_payment = calculate_monthly_payment
    annual_rate = mortgage.interest_rate
    monthly_rate = (annual_rate / 12.0) / 100.0
    extra_payment = mortgage.projection&.monthly_contribution || 0

    balance = mortgage.balance
    schedule = []

    num_months.times do |i|
      starting_balance = balance

      # Calculate interest on current balance
      interest_payment = balance * monthly_rate

      # Principal payment is remainder
      principal_payment = monthly_payment - interest_payment

      # Add extra payment (all goes to principal)
      total_principal = principal_payment + extra_payment

      # Update balance
      balance = [balance - total_principal, 0].max

      schedule << {
        month: i + 1,
        starting_balance: starting_balance.round(2),
        interest_payment: interest_payment.round(2),
        principal_payment: principal_payment.round(2),
        extra_payment: extra_payment.round(2),
        total_payment: (monthly_payment + extra_payment).round(2),
        ending_balance: balance.round(2)
      }

      # Stop if loan is paid off
      break if balance == 0
    end

    schedule
  end
end
