class AdjustmentsController < ApplicationController
  before_action :set_account

  def new
    @adjustment = @account.adjustments.new(adjusted_at: Time.current)
  end

  def create
    if params[:adjustment][:new_balance].present?
      # Set Balance mode: calculate adjustment from new_balance
      new_balance = params[:adjustment][:new_balance].to_f
      calculated_amount = new_balance - @account.balance
      @adjustment = @account.adjustments.new(
        amount: calculated_amount,
        description: params[:adjustment][:description],
        adjusted_at: Time.current
      )
    else
      # Add Adjustment mode: use provided amount
      @adjustment = @account.adjustments.new(adjustment_params)
    end

    Account.transaction do
      @adjustment.save!
      @account.update!(balance: @account.balance + @adjustment.amount)
    end

    redirect_to account_path(@account), notice: "Adjustment was successfully added."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def adjustment_params
    params.require(:adjustment).permit(:amount, :description, :adjusted_at)
  end
end
