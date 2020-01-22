# frozen_string_literal: true

class Staff::FundsController < Staff::BaseController
  include Secured

  def index
    @funds = policy_scope(Fund)
  end

  def show
    @fund = Fund.find(id)
    authorize @fund

    transactions = policy_scope(Transaction).where(fund: @fund)
    @transaction_presenters = transactions.map { |transaction| TransactionPresenter.new(transaction) }

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def new
    @fund = Fund.new
    @organisation = Organisation.find(organisation_id)
    authorize @fund
  end

  def create
    @fund = Fund.new
    @fund.organisation = Organisation.find(organisation_id)
    authorize @fund

    @fund.wizard_status = "identifier"
    @fund.save(validate: false)

    redirect_to fund_step_path(@fund.id, @fund.wizard_status)
  end

  def edit
    @fund = Fund.find(id)
    authorize @fund
  end

  def update
    @fund = Fund.find(id)
    authorize @fund

    @fund.assign_attributes(fund_params)

    if @fund.valid?
      @fund.save
      flash[:notice] = I18n.t("form.fund.update.success")
      redirect_to organisation_fund_path(@fund.organisation, @fund)
    else
      render :edit
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
