# frozen_string_literal: true

class Staff::FundsController < Staff::BaseController
  include Secured

  def index
    @funds = policy_scope(Fund)
    authorize @funds
  end

  def show
    @fund = policy_scope(Fund).find(id)
    authorize @fund

    @transactions = policy_scope(Transaction)
  end

  def new
    @fund = policy_scope(Fund).new
    authorize @fund
  end

  def create
    @fund = policy_scope(Fund).new(fund_params)
    authorize @fund
    @fund.organisation = Organisation.find params[:organisation_id]

    if @fund.valid?
      @fund.save
      flash[:notice] = I18n.t("form.fund.create.success")
      redirect_to fund_path(@fund)
    else
      render :new
    end
  end

  private

  def fund_params
    params.require(:fund).permit(:name, :organisation_id)
  end

  def id
    params[:id]
  end
end
