# frozen_string_literal: true

class Staff::FundsController < Staff::BaseController
  include Secured

  def index
    @funds = funds_for_current_user
  end

  def show
    @fund = Fund.find(id)
  end

  def new
    @fund = Fund.new
    @organisations = current_user.organisations.collect { |organisation| [organisation.name, organisation.id] }
  end

  def create
    @fund = Fund.new(fund_params)

    if @fund.valid?
      @fund.save
      flash[:notice] = I18n.t("form.fund.create.success")
      redirect_to fund_path(@fund)
    else
      render :new
    end
  end

  private

  def funds_for_current_user
    Fund.for_user(current_user)
  end

  def fund_params
    params.require(:fund).permit(:name, :organisation_id)
  end

  def id
    params[:id]
  end
end
