class ForecastHistory
  SequenceError = Class.new(StandardError)

  attr_reader :financial_year, :financial_quarter, :history_recorder

  def initialize(activity, financial_quarter:, financial_year:, report: nil, user: nil)
    @activity = activity
    @financial_quarter = financial_quarter.to_i
    @financial_year = financial_year.to_i
    @report = report
    @user = user
    @history_recorder = HistoryRecorder.new(user: user)
  end

  def set_value(value)
    value = ConvertFinancialValue.new.convert(value.to_s)
    latest_entry = find_latest_entry

    return if latest_entry&.value == value

    if record_history?
      update_history(latest_entry, value)
    else
      edit_in_place(latest_entry, value)
    end
  end

  def clear
    set_value(0)
  end

  def all_entries
    entries.to_a.reverse
  end

  def latest_entry
    find_latest_entry
  end

  private

  def record_history?
    !@activity.organisation.service_owner?
  end

  def find_latest_entry
    entries.first
  end

  def entries
    entries = Forecast.unscoped.where(series_attributes)

    if record_history?
      entries.joins(:report).merge(Report.in_historical_order)
    else
      entries.order(forecast_type: :desc)
    end
  end

  def update_history(latest_entry, value)
    report = @report || Report.editable_for_activity(@activity)
    check_forecast_in_future(report)

    if latest_entry&.report_id == report.id
      update_entry(latest_entry, value)
    elsif latest_entry
      new_entry = revise_entry(latest_entry, value, report)
      record_historical_event(latest_entry, new_entry, report)
      new_entry
    else
      create_original_entry(value, report)
    end
  end

  def check_forecast_in_future(report)
    raise SequenceError unless report

    year, quarter = report.financial_year, report.financial_quarter
    return unless year && quarter

    unless forecast_in_future(year, quarter)
      raise SequenceError
    end
  end

  def edit_in_place(latest_entry, value)
    if latest_entry.nil?
      create_original_entry(value)
    elsif latest_entry.original?
      revise_entry(latest_entry, value)
    elsif latest_entry.revised?
      update_entry(latest_entry, value)
    end
  end

  def create_original_entry(value, report = nil)
    return if value == 0

    attributes = series_attributes.merge(required_attributes).merge(
      forecast_type: :original,
      value: value,
      report: report
    )

    Forecast.unscoped.create!(attributes)
  end

  def revise_entry(entry, value, report = nil)
    new_entry = entry.dup

    new_entry.update!(
      forecast_type: :revised,
      value: value,
      report: report
    )
    new_entry
  end

  def record_historical_event(old_entry, new_entry, report)
    history_recorder.call(
      changes: {value: [old_entry.value, new_entry.value]},
      reference: "Revising a forecast for #{old_entry.own_financial_quarter}",
      activity: new_entry.parent_activity,
      trackable: new_entry,
      report: report
    )
  end

  def update_entry(entry, value)
    if value == 0 && entries.count == 1
      entry.destroy!
      return
    end
    entry.update!(value: value)
    entry
  end

  def series_attributes
    {
      parent_activity: @activity,
      financial_quarter: @financial_quarter,
      financial_year: @financial_year
    }
  end

  def required_attributes
    start_date, end_date = period_start_and_end_dates
    service_owner = Organisation.service_owner

    {
      period_start_date: start_date,
      period_end_date: end_date,
      providing_organisation_name: service_owner.name,
      providing_organisation_type: service_owner.organisation_type,
      providing_organisation_reference: service_owner.iati_reference,
      currency: @activity.organisation.default_currency
    }
  end

  def period_start_and_end_dates
    quarter = FinancialQuarter.new(@financial_year.to_i, @financial_quarter.to_i)

    [
      quarter.start_date,
      quarter.end_date
    ]
  end

  private def forecast_in_future(year, quarter)
    year < @financial_year || (year == @financial_year && quarter < @financial_quarter)
  end
end
