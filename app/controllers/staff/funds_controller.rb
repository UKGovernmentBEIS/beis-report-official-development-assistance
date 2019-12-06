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

    transactions = policy_scope(Transaction)
    @transaction_presenters = transactions.map { |transaction| TransactionPresenter.new(transaction) }
  end

  def new
    @fund = policy_scope(Fund).new
    @organisation = Organisation.find(organisation_id)
    authorize @fund
  end

  def create
    @fund = policy_scope(Fund).new(fund_params)
    @organisation = Organisation.find(organisation_id)
    @fund.organisation = @organisation
    authorize @fund

    if @fund.valid?
      @fund.save
      flash[:notice] = I18n.t("form.fund.create.success")
      redirect_to organisation_fund_path(@organisation, @fund)
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

  def organisation_id
    params[:organisation_id]
  end
end
