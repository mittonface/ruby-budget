require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should create mortgage" do
    assert_difference("Mortgage.count", 1) do
      post accounts_url, params: {
        account: {
          type: "Mortgage",
          name: "Home Loan",
          opened_at: Date.current,
          principal: 300000.0,
          interest_rate: 3.5,
          term_years: 30,
          loan_start_date: Date.current
        }
      }
    end

    assert_redirected_to account_url(Account.last)

    mortgage = Mortgage.last
    assert_equal "Home Loan", mortgage.name
    assert_equal 300000.0, mortgage.balance
    assert_equal 300000.0, mortgage.principal
  end

  test "should create savings account" do
    assert_difference("SavingsAccount.count", 1) do
      post accounts_url, params: {
        account: {
          type: "SavingsAccount",
          name: "Emergency Fund",
          initial_balance: 5000.0,
          opened_at: Date.current
        }
      }
    end

    assert_redirected_to account_url(Account.last)

    savings = SavingsAccount.last
    assert_equal "Emergency Fund", savings.name
    assert_equal 5000.0, savings.balance
  end
end
