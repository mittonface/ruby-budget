require "test_helper"

class ProjectionTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )
  end

  test "valid projection" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert projection.valid?
  end

  test "requires account" do
    projection = Projection.new(
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:account], "must exist"
  end

  test "requires monthly_contribution" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: nil,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:monthly_contribution], "can't be blank"
  end

  test "monthly_contribution must be non-negative" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: -100,
      annual_return_rate: 5.0
    )
    assert_not projection.valid?
    assert_includes projection.errors[:monthly_contribution], "must be greater than or equal to 0"
  end

  test "allows zero monthly_contribution" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 0,
      annual_return_rate: 5.0
    )
    assert projection.valid?
  end

  test "requires annual_return_rate" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00
    )
    assert_not projection.valid?
    assert_includes projection.errors[:annual_return_rate], "can't be blank"
  end

  test "allows negative annual_return_rate" do
    projection = Projection.new(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: -2.0
    )
    assert projection.valid?
  end

  test "destroyed when account destroyed" do
    projection = Projection.create!(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )
    assert_difference("Projection.count", -1) do
      @account.destroy
    end
  end

  test "account can have only one projection" do
    Projection.create!(
      account: @account,
      monthly_contribution: 500.00,
      annual_return_rate: 5.0
    )

    # Attempting to create a second projection should fail at DB level
    # due to unique index on account_id
    second_projection = Projection.new(
      account: @account,
      monthly_contribution: 1000.00,
      annual_return_rate: 7.0
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      second_projection.save(validate: false)
    end
  end
end
