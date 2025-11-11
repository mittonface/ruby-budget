class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = Account.all.order(created_at: :desc)
  end

  def show
    @adjustments = @account.adjustments.order(adjusted_at: :desc)

    if @account.is_a?(Mortgage)
      # Calculate mortgage-specific data
      calculator = MortgageCalculator.new(@account)
      @monthly_payment = calculator.calculate_monthly_payment
      @payment_breakdown = calculator.calculate_payment_breakdown
      @amortization_schedule = calculator.generate_amortization_schedule(360) # 30 years max
      @payoff_date = calculator.calculate_payoff_date
    elsif @account.projection && @account.projection.target_date.present?
      # Calculate projection for savings accounts
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
    # Use type param to instantiate correct subclass
    account_class = account_type_class
    @account = account_class.new(account_params)

    # Set balance based on account type
    if @account.is_a?(Mortgage)
      @account.balance = @account.principal
      @account.initial_balance = @account.principal
    else
      @account.balance = @account.initial_balance
    end

    if @account.save
      redirect_to account_url(@account), notice: "Account was successfully created."
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

  def account_type_class
    type = params.dig(:account, :type)
    return Account unless type.present?

    # Whitelist allowed account types
    case type
    when "SavingsAccount"
      SavingsAccount
    when "Mortgage"
      Mortgage
    else
      Account
    end
  end

  def account_params
    permitted = [ :name, :initial_balance, :opened_at, :type ]

    # Add mortgage-specific params if creating a Mortgage
    if params.dig(:account, :type) == "Mortgage"
      permitted += [ :principal, :interest_rate, :term_years, :loan_start_date ]
    end

    params.require(:account).permit(permitted)
  end
end
