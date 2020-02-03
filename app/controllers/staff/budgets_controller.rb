class Staff::BudgetsController < Staff::BaseController
  include Secured
  include DateHelper

  def new
    @activity = Activity.find(activity_id)
    @budget = Budget.new
    @budget.activity = @activity

    authorize @budget

    unless @activity.is_programme_level?
      flash[:warning] = I18n.t("page_title.errors.budget.not_possible")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    end
  end

  def create
    @activity = Activity.find(activity_id)
    @budget = Budget.new(budget_params)
    @budget.activity = @activity
    authorize @budget

    @budget.value = monetary_value
    @budget.period_start_date = format_date(period_start_date)
    @budget.period_end_date = format_date(period_end_date)

    if @budget.save
      flash[:notice] = I18n.t("form.budget.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  private

  def activity_id
    params[:activity_id]
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
