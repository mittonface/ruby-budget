class Account < ApplicationRecord
  has_many :adjustments, dependent: :destroy

  validates :name, presence: true
  validates :balance, presence: true, numericality: true
  validates :initial_balance, presence: true, numericality: true
  validates :opened_at, presence: true
end
