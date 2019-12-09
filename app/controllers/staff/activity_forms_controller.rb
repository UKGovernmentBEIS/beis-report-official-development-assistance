class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper

  steps(
    :identifier,
    :purpose,
    :sector,
    :status,
    :dates,
    :country,
    :flow,
    :finance,
    :aid_type,
    :tied_status,
  )

  def index
    skip_policy_scope
    authorize :activity, :index?

    super
  end

  def show
    @page_title = t("page_title.activity_form.show.#{step}")

    @activity = policy_scope(Activity).find(params[:activity_id])
    @fund = policy_scope(Fund).find(params[:fund_id])
    authorize @activity

    render_wizard
  end

  def update
    @page_title = t("page_title.activity_form.show.#{step}")

    @activity = policy_scope(Activity).find(params[:activity_id])
    @fund = policy_scope(Fund).find(params[:fund_id])
    authorize @activity

    case step
    when :dates
      @activity.planned_start_date = format_date(planned_start_date)
      @activity.planned_end_date = format_date(planned_end_date)
      @activity.actual_start_date = format_date(actual_start_date)
      @activity.actual_end_date = format_date(actual_end_date)
    else
      @activity.update(activity_params)
    end

    render_wizard @activity
  end

  private

  def planned_start_date
    params[:planned_start_date]
  end

  def planned_end_date
    params[:planned_end_date]
  end

  def actual_start_date
    params[:actual_start_date]
  end

  def actual_end_date
    params[:actual_end_date]
  end

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :recipient_region, :flow, :finance, :aid_type, :tied_status)
  end

  def finish_wizard_path
    flash[:notice] = I18n.t("form.activity.create.success")

    fund_path(@fund)
  end
end
