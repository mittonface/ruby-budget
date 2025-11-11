require "test_helper"

class SavingsAccountTest < ActiveSupport::TestCase
  test "should inherit from Account" do
    account = SavingsAccount.new(
      name: "Test Savings",
      balance: 1000.0,
      initial_balance: 1000.0,
      opened_at: Date.current
    )

    assert account.is_a?(Account)
    assert_equal "SavingsAccount", account.type
  end

  test "should save with valid attributes" do
    account = SavingsAccount.new(
      name: "Emergency Fund",
      balance: 5000.0,
      initial_balance: 5000.0,
      opened_at: 1.year.ago
    )

    assert account.save
    assert_equal "SavingsAccount", account.type
  end

  test "should validate presence of required fields" do
    account = SavingsAccount.new

    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
    assert_includes account.errors[:opened_at], "can't be blank"
  end
end
