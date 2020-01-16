# frozen_string_literal: true

class Staff::ProgrammesController < Staff::BaseController
  include Secured

  def show
    @programme = Programme.find(id)
    authorize @programme
  end

  def new
    @programme = Programme.new
    @fund = Fund.find(fund_id)
    @organisation = @fund.organisation

    authorize @programme
  end

  def create
    @programme = Programme.new(programme_params)
    @fund = Fund.find(fund_id)
    @programme.fund = @fund
    @programme.organisation = @fund.organisation

    authorize @programme

    if @programme.valid?
      @programme.save
      flash[:notice] = I18n.t("form.programme.create.success")
      redirect_to fund_programme_path(@fund, @programme)
    else
      render :new
    end
  end

  private

  def programme_params
    params.require(:programme).permit(:name)
  end

  def id
    params[:id]
  end

  def fund_id
    params[:fund_id]
  end
end
