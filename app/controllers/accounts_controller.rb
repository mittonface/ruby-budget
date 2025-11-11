class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = Account.all.order(created_at: :desc)
  end

  def show
    @adjustments = @account.adjustments.order(adjusted_at: :desc)

    # Calculate projection if target_date is saved
    if @account.projection && @account.projection.target_date.present?
      calculator = ProjectionCalculator.new(
        projection: @account.projection,
        current_balance: @account.balance,
        target_date: @account.projection.target_date
      )
      @projection_result = calculator.calculate
    end
  end

  def new
    @account = Account.new(opened_at: Date.current, initial_balance: 0)
  end

  def create
    @account = Account.new(account_params)
    @account.balance = @account.initial_balance

    if @account.save
      redirect_to @account, notice: "Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_path, notice: "Account was successfully deleted."
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :initial_balance, :opened_at)
  end
end
