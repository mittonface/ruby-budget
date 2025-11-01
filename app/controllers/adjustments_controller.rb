class AdjustmentsController < ApplicationController
  before_action :set_account

  def new
    @adjustment = @account.adjustments.new(adjusted_at: Time.current)
  end

  def create
    @adjustment = @account.adjustments.new(adjustment_params)

    Account.transaction do
      @adjustment.save!
      @account.update!(balance: @account.balance + @adjustment.amount)
    end

    redirect_to @account, notice: "Adjustment was successfully added."
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
