require "test_helper"

class ProjectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(
      name: "Test Account",
      balance: 1000.00,
      initial_balance: 1000.00,
      opened_at: Time.current
    )
  end

  test "should get edit when no projection exists" do
    get edit_account_projection_url(@account)
    assert_response :success
    assert_select "form"
  end

  test "should get edit when projection exists" do
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    get edit_account_projection_url(@account)
    assert_response :success
    assert_select "form"
    assert_select "input[value='500.0']"
    assert_select "input[value='5.0']"
  end

  test "should create projection with valid params" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 600,
          annual_return_rate: 7.0
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_equal "Projection settings saved.", flash[:notice]

    @account.reload
    assert_equal 600.0, @account.projection.monthly_contribution.to_f
    assert_equal 7.0, @account.projection.annual_return_rate.to_f
  end

  test "should update existing projection" do
    @projection = Projection.create!(
      account: @account,
      monthly_contribution: 500,
      annual_return_rate: 5.0
    )

    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 800,
          annual_return_rate: 6.5
        }
      }
    end

    assert_redirected_to account_url(@account)

    @projection.reload
    assert_equal 800.0, @projection.monthly_contribution.to_f
    assert_equal 6.5, @projection.annual_return_rate.to_f
  end

  test "should not create projection with negative contribution" do
    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: -100,
          annual_return_rate: 5.0
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "should not create projection without annual_return_rate" do
    assert_no_difference("Projection.count") do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 500,
          annual_return_rate: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should allow zero monthly_contribution" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 0,
          annual_return_rate: 5.0
        }
      }
    end

    assert_redirected_to account_url(@account)
  end

  test "should allow negative annual_return_rate" do
    assert_difference("Projection.count", 1) do
      patch account_projection_url(@account), params: {
        projection: {
          monthly_contribution: 500,
          annual_return_rate: -2.0
        }
      }
    end

    assert_redirected_to account_url(@account)
  end
end
