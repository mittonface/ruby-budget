require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account with required attributes" do
    account = Account.new(
      name: "Emergency Fund",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(
      balance: 0,
      initial_balance: 0,
      opened_at: Time.current
    )
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires balance" do
    account = Account.new(
      name: "Test Account",
      initial_balance: 0,
      opened_at: Time.current
    )
    account.balance = nil
    assert_not account.valid?
    assert_includes account.errors[:balance], "can't be blank"
  end

  test "requires initial_balance" do
    account = Account.new(
      name: "Test Account",
      balance: 0,
      opened_at: Time.current
    )
    account.initial_balance = nil
    assert_not account.valid?
    assert_includes account.errors[:initial_balance], "can't be blank"
  end

  test "requires opened_at" do
    account = Account.new(
      name: "Test Account",
      balance: 0,
      initial_balance: 0
    )
    assert_not account.valid?
    assert_includes account.errors[:opened_at], "can't be blank"
  end

  test "balance must be numeric" do
    account = Account.new(
      name: "Test Account",
      balance: "not a number",
      initial_balance: 0,
      opened_at: Time.current
    )
    assert_not account.valid?
    assert_includes account.errors[:balance], "is not a number"
  end

  test "has many adjustments" do
    account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )

    adjustment = account.adjustments.create!(
      amount: 100.00,
      adjusted_at: Time.current
    )

    assert_includes account.adjustments, adjustment
  end

  test "destroys associated adjustments when destroyed" do
    account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )

    adjustment = account.adjustments.create!(
      amount: 100.00,
      adjusted_at: Time.current
    )

    adjustment_id = adjustment.id
    account.destroy

    assert_nil Adjustment.find_by(id: adjustment_id)
  end
end
