require "test_helper"

class AdjustmentTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )
  end

  test "valid adjustment with required attributes" do
    adjustment = @account.adjustments.new(
      amount: 100.00,
      adjusted_at: Time.current
    )
    assert adjustment.valid?
  end

  test "requires amount" do
    adjustment = @account.adjustments.new(
      adjusted_at: Time.current
    )
    assert_not adjustment.valid?
    assert_includes adjustment.errors[:amount], "can't be blank"
  end

  test "amount cannot be zero" do
    adjustment = @account.adjustments.new(
      amount: 0,
      adjusted_at: Time.current
    )
    assert_not adjustment.valid?
    assert_includes adjustment.errors[:amount], "must be other than 0"
  end

  test "requires adjusted_at" do
    adjustment = @account.adjustments.new(
      amount: 100.00
    )
    assert_not adjustment.valid?
    assert_includes adjustment.errors[:adjusted_at], "can't be blank"
  end

  test "belongs to account" do
    adjustment = @account.adjustments.create!(
      amount: 100.00,
      adjusted_at: Time.current
    )
    assert_equal @account, adjustment.account
  end

  test "amount can be positive (deposit)" do
    adjustment = @account.adjustments.new(
      amount: 500.00,
      adjusted_at: Time.current
    )
    assert adjustment.valid?
    assert adjustment.amount.positive?
  end

  test "amount can be negative (withdrawal)" do
    adjustment = @account.adjustments.new(
      amount: -200.00,
      adjusted_at: Time.current
    )
    assert adjustment.valid?
    assert adjustment.amount.negative?
  end

  test "description is optional" do
    adjustment = @account.adjustments.new(
      amount: 100.00,
      adjusted_at: Time.current,
      description: nil
    )
    assert adjustment.valid?
  end

  test "orders by adjusted_at descending by default" do
    older = @account.adjustments.create!(
      amount: 100.00,
      adjusted_at: 2.days.ago
    )
    newer = @account.adjustments.create!(
      amount: 50.00,
      adjusted_at: 1.day.ago
    )

    adjustments = @account.adjustments.to_a
    assert_equal newer, adjustments.first
    assert_equal older, adjustments.last
  end
end
