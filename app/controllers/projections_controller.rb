class ProjectionsController < ApplicationController
  before_action :set_account

  def edit
    @projection = @account.projection || @account.build_projection
  end

  def update
    @projection = @account.projection || @account.build_projection

    if @projection.update(projection_params)
      redirect_to @account, notice: "Projection settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def projection_params
    params.require(:projection).permit(:monthly_contribution, :annual_return_rate)
  end
end
