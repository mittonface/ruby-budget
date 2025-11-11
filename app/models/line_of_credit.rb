class LineOfCredit < Account
  # Validations for line of credit accounts
  validates :credit_limit, presence: true, numericality: { greater_than: 0 }
  validates :apr, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Balance represents amount owed (liability)
  # Credit limit represents maximum borrowing capacity
end
