class ProjectionCalculator
  def initialize(projection:, current_balance:, target_date:)
    @projection = projection
    @current_balance = current_balance.to_d
    @target_date = target_date
  end

  def calculate
    balance = @current_balance
    monthly_rate = (@projection.annual_return_rate / 100.0) / 12.0
    breakdown = []

    current_date = Date.today

    while current_date <= @target_date
      # Add monthly contribution first
      balance += @projection.monthly_contribution

      # Apply compound interest
      interest = balance * monthly_rate
      balance += interest

      breakdown << {
        date: current_date,
        balance: balance.round(2),
        contribution: @projection.monthly_contribution.round(2),
        interest: interest.round(2)
      }

      current_date = current_date.next_month
    end

    {
      final_balance: balance.round(2),
      monthly_breakdown: breakdown
    }
  end
end
