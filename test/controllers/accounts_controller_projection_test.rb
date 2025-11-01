require "test_helper"

class AccountsControllerProjectionTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(
      name: "Test Account",
      balance: 10000.00,
      initial_balance: 10000.00,
      opened_at: Time.current
    )
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 6.0
    )
  end

  test "show page without target_date does not calculate projection" do
    get account_url(@account)
    assert_response :success
    assert_nil assigns(:projection_result)
  end

  test "show page with target_date calculates projection" do
    target_date = Date.today + 12.months

    get account_url(@account), params: { target_date: target_date.to_s }
    assert_response :success

    result = assigns(:projection_result)
    assert_not_nil result
    assert result[:final_balance] > 10000.00
    assert_not_empty result[:monthly_breakdown]
  end

  test "show page without projection does not calculate even with target_date" do
    @account.projection.destroy

    get account_url(@account), params: { target_date: (Date.today + 1.year).to_s }
    assert_response :success
    assert_nil assigns(:projection_result)
  end

  test "show page with invalid target_date handles gracefully" do
    get account_url(@account), params: { target_date: "invalid" }
    assert_response :success
    # Should not crash, either shows error or ignores
  end
end
