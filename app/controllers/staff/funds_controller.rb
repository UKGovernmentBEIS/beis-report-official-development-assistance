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

    @programmes = @fund.programmes

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
    @fund = Fund.new(fund_params)
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
