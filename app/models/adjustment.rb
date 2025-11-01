class Adjustment < ApplicationRecord
  belongs_to :account

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :adjusted_at, presence: true

  default_scope -> { order(adjusted_at: :desc) }
end
