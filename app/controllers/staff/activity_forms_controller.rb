class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard

  steps :everything

  def index
    skip_policy_scope
    authorize :activity, :index?

    super
  end

  def show
    @activity = policy_scope(Activity).find(params[:activity_id])
    @fund = policy_scope(Fund).find(params[:fund_id])
    authorize @activity

    render_wizard
  end

  def update
    @activity = policy_scope(Activity).find(params[:activity_id])
    @fund = policy_scope(Fund).find(params[:fund_id])
    authorize @activity

    @activity.update(activity_params)

    @activity.planned_start_date = format_date(planned_start_date)
    @activity.planned_end_date = format_date(planned_end_date)
    @activity.actual_start_date = format_date(actual_start_date)
    @activity.actual_end_date = format_date(actual_end_date)

    render_wizard @activity, notice: I18n.t("form.activity.create.success")
  end

  private

  def format_date(params)
    date_parts = params.values_at(:day, :month, :year)
    return unless date_parts.all?(&:present?)

    day, month, year = date_parts.map(&:to_i)
    Date.new(year, month, day)
  end

  def planned_start_date
    params.require(:planned_start_date).permit(:day, :month, :year)
  end

  def planned_end_date
    params.require(:planned_end_date).permit(:day, :month, :year)
  end

  def actual_start_date
    params.require(:actual_start_date).permit(:day, :month, :year)
  end

  def actual_end_date
    params.require(:actual_end_date).permit(:day, :month, :year)
  end

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :recipient_region, :flow, :finance, :aid_type, :tied_status)
  end

  def finish_wizard_path
    fund_activity_path(@fund, @activity)
  end
end
