# frozen_string_literal: true

class Staff::ForecastsController < Staff::BaseController
  include Activities::Breadcrumbed

  def new
    @activity = Activity.find(params["activity_id"])
    @forecast = Forecast.unscoped.new
    @forecast.parent_activity = @activity
    pre_fill_financial_quarter_and_year

    authorize @forecast

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.forecast.new"), new_activity_forecast_path(@activity)
  end

  def create
    @activity = Activity.find(params["activity_id"])
    authorize @activity

    history = history_for_create

    begin
      history.set_value(forecast_params[:value])
    rescue ForecastHistory::SequenceError
      @forecast = Forecast.unscoped.new(forecast_params)
      @forecast.parent_activity = @activity
      @forecast.errors.add(:financial_quarter, :in_the_past)
      render :new
      return
    rescue ConvertFinancialValue::Error
      @forecast = Forecast.unscoped.new(forecast_params)
      @forecast.parent_activity = @activity
      @forecast.errors.add(:value, :not_a_number)
      render :new
      return
    end

    flash[:notice] = t("action.forecast.create.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  def edit
    @activity = Activity.find(params["activity_id"])
    history = history_for_update
    @forecast = ForecastPresenter.new(history.latest_entry)
    authorize @forecast

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.forecast.edit", quarter: @forecast.financial_quarter_and_year), edit_activity_forecasts_path(@activity, @forecast.financial_year, @forecast.financial_quarter)
  end

  def update
    @activity = Activity.find(params["activity_id"])
    history = history_for_update
    @forecast = history.latest_entry
    authorize @forecast

    begin
      history.set_value(forecast_params[:value])
    rescue ConvertFinancialValue::Error
      @forecast = ForecastPresenter.new(history.latest_entry)
      @forecast.value = forecast_params[:value]
      @forecast.errors.add(:value, :not_a_number)
      render :edit
      return
    end

    flash[:notice] = t("action.forecast.update.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  def destroy
    @activity = Activity.find(params["activity_id"])
    history = history_for_update
    authorize history.latest_entry

    history.clear

    flash[:notice] = t("action.forecast.destroy.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  private def history_for_create
    ForecastHistory.new(
      @activity,
      financial_quarter: forecast_params[:financial_quarter],
      financial_year: forecast_params[:financial_year],
      user: current_user
    )
  end

  private def history_for_update
    ForecastHistory.new(
      @activity,
      financial_quarter: params[:quarter],
      financial_year: params[:year],
      user: current_user
    )
  end

  private def forecast_params
    params.require(:forecast).permit(
      :currency,
      :value,
      :financial_quarter,
      :financial_year
    )
  end

  private def pre_fill_financial_quarter_and_year
    @forecast.financial_quarter = FinancialQuarter.for_date(Date.today).to_i
    @forecast.financial_year = FinancialYear.for_date(Date.today).to_i
  end
end
