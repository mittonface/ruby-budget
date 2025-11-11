require "test_helper"

class MortgageTest < ActiveSupport::TestCase
  test "should inherit from Account" do
    mortgage = Mortgage.new(
      name: "Home Loan",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: 300000.0,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    assert mortgage.is_a?(Account)
    assert_equal "Mortgage", mortgage.type
  end

  test "should validate presence of mortgage fields" do
    mortgage = Mortgage.new

    assert_not mortgage.valid?
    assert_includes mortgage.errors[:principal], "can't be blank"
    assert_includes mortgage.errors[:interest_rate], "can't be blank"
    assert_includes mortgage.errors[:term_years], "can't be blank"
    assert_includes mortgage.errors[:loan_start_date], "can't be blank"
  end

  test "should validate numericality of principal" do
    mortgage = Mortgage.new(
      name: "Home Loan",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: -100,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    assert_not mortgage.valid?
    assert_includes mortgage.errors[:principal], "must be greater than 0"
  end

  test "should validate numericality of interest_rate" do
    mortgage = Mortgage.new(
      name: "Home Loan",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: 300000.0,
      interest_rate: -1,
      term_years: 30,
      loan_start_date: Date.current
    )

    assert_not mortgage.valid?
    assert_includes mortgage.errors[:interest_rate], "must be greater than or equal to 0"
  end

  test "should validate numericality of term_years" do
    mortgage = Mortgage.new(
      name: "Home Loan",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: 300000.0,
      interest_rate: 3.5,
      term_years: 0,
      loan_start_date: Date.current
    )

    assert_not mortgage.valid?
    assert_includes mortgage.errors[:term_years], "must be greater than 0"
  end

  test "should save with valid attributes" do
    mortgage = Mortgage.new(
      name: "Home Loan",
      balance: 300000.0,
      initial_balance: 300000.0,
      opened_at: Date.current,
      principal: 300000.0,
      interest_rate: 3.5,
      term_years: 30,
      loan_start_date: Date.current
    )

    assert mortgage.save
    assert_equal "Mortgage", mortgage.type
    assert_equal 300000.0, mortgage.principal
  end
end
