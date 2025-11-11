require "test_helper"

class AdjustmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(
      name: "Test Account",
      balance: 1000,
      initial_balance: 1000,
      opened_at: Date.current
    )
  end

  test "should create adjustment with amount in add adjustment mode" do
    assert_difference("Adjustment.count") do
      post account_adjustments_url(@account), params: {
        adjustment: {
          amount: 500,
          description: "Deposit",
          adjusted_at: Time.current
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_equal 1500, @account.reload.balance
    assert_equal 500, @account.adjustments.last.amount
  end

  test "should create adjustment with new_balance in set balance mode" do
    assert_difference("Adjustment.count") do
      post account_adjustments_url(@account), params: {
        adjustment: {
          new_balance: 1500,
          description: "Balance correction"
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_equal 1500, @account.reload.balance
    assert_equal 500, @account.adjustments.last.amount # Calculated: 1500 - 1000
    assert_equal "Balance correction", @account.adjustments.last.description
  end

  test "should reject new_balance equal to current balance" do
    assert_no_difference("Adjustment.count") do
      post account_adjustments_url(@account), params: {
        adjustment: {
          new_balance: 1000,
          description: "No change"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should prioritize new_balance over amount when both provided" do
    assert_difference("Adjustment.count") do
      post account_adjustments_url(@account), params: {
        adjustment: {
          amount: 999,
          new_balance: 2000,
          description: "Test"
        }
      }
    end

    assert_equal 2000, @account.reload.balance
    assert_equal 1000, @account.adjustments.last.amount # From new_balance, not amount
  end
end
