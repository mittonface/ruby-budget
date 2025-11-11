class Mortgage < Account
  # Mortgage-specific validations
  validates :principal, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_years, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :loan_start_date, presence: true

  # Balance represents remaining principal owed (liability)
end
