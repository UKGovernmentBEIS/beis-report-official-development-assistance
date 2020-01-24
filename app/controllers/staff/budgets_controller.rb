class Staff::BudgetsController < Staff::BaseController
  include Secured
  include DateHelper

  def new
    @programme = Programme.find(programme_id)
    @activity = Activity.find_by(hierarchy_id: @programme.id)
    @budget = Budget.new
    @budget.activity = @activity

    authorize @budget
  end

  def create
    @programme = Programme.find(programme_id)
    @budget = Budget.new(budget_params)
    @budget.activity = Activity.find_by(hierarchy: @programme)
    authorize @budget

    @budget.value = monetary_value
    @budget.period_start_date = format_date(period_start_date)
    @budget.period_end_date = format_date(period_end_date)

    if @budget.save
      flash[:notice] = I18n.t("form.budget.create.success")
      redirect_to fund_programme_path(@programme.fund, @programme)
    else
      render :new
    end
  end

  private

  def programme_id
    params[:programme_id]
  end

  def budget_params
    params.require(:budget).permit(:budget_type, :status, :value)
  end

  def monetary_value
    @monetary_value ||= begin
                          string_value = params.require(:budget).permit(:value)
                          Monetize.parse(string_value).to_f
                        end
  end

  def period_start_date
    date_fields = params.require(:budget).permit("period_start_date(3i)", "period_start_date(2i)", "period_start_date(1i)")
    {day: date_fields["period_start_date(3i)"], month: date_fields["period_start_date(2i)"], year: date_fields["period_start_date(1i)"]}
  end

  def period_end_date
    date_fields = params.require(:budget).permit("period_end_date(3i)", "period_end_date(2i)", "period_end_date(1i)")
    {day: date_fields["period_end_date(3i)"], month: date_fields["period_end_date(2i)"], year: date_fields["period_end_date(1i)"]}
  end
end
