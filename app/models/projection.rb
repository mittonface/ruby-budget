class Projection < ApplicationRecord
  belongs_to :account

  validates :monthly_contribution, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :annual_return_rate, presence: true, numericality: true
end
