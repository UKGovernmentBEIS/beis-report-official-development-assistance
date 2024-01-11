class Export::ContinuingActivities
  def filename
    "continuing_activities.csv"
  end

  def headers
    [
      "Partner Organisation name",
      "Activity name",
      "RODA ID",
      "Current Transparency identifier",
      "Future Transparency identifier",
      "Current Previous identifier",
      "Future Previous identifier",
      "Partner Organisation ID",
      "Status",
      "Level"
    ]
  end

  def rows
    activities.map do |activity|
      partner_organisation_name = activity.organisation.name
      activity_title = activity.title
      roda_identifier = activity.roda_identifier
      current_transparency_identifier = activity.transparency_identifier
      future_transparency_identifier = current_transparency_identifier&.sub(/\AGB-GOV-13/, "GB-GOV-26")
      current_previous_identifier = activity.previous_identifier
      future_previous_identifier = current_transparency_identifier
      partner_organisation_identifier = activity.partner_organisation_identifier
      status = I18n.t("activity.programme_status.#{activity.programme_status}")
      level = I18n.t("table.body.activity.level.#{activity.level}")

      [
        partner_organisation_name,
        activity_title,
        roda_identifier,
        current_transparency_identifier,
        future_transparency_identifier,
        current_previous_identifier,
        future_previous_identifier,
        partner_organisation_identifier,
        status,
        level
      ]
    end
  end

  def activities
    # active statuses, regardless of any associated actual spend
    definitely_active = Activity
      .joins(:organisation)
      .includes(:organisation)
      .where.not(level: "fund")
      .where(is_oda: [nil, true])
      .where.not(programme_status: ["completed", "stopped", "cancelled", "finalisation", "paused"])
      .order("organisations.name, programme_status")

    cut_off_quarter = FinancialQuarter.new(2022, 4)

    # activities that MAY need to continue, IF they have actual spend more recent than FQ4 2022-2023
    potentially_active_due_to_actuals = Activity
      .joins(:organisation, :actuals)
      .includes(:organisation)
      .where.not(level: "fund")
      .where(is_oda: [nil, true])
      .where(programme_status: ["completed", "stopped", "cancelled", "finalisation", "paused"])
      .where("transactions.date > ?", cut_off_quarter.end_date)
      .order("organisations.name, programme_status")

    # activities that MAY need to continue, IF they have forecasts for quarters after FQ4 2022-2023
    potentially_active_due_to_forecasts = Activity
      .joins(:organisation)
      .includes(:organisation)
      .where.not(level: "fund")
      .where(is_oda: [nil, true])
      .where(programme_status: "paused")
      .order("organisations.name, programme_status")
    potentially_active_due_to_forecasts = potentially_active_due_to_forecasts.select do |activity|
      Forecast.unscoped.where(parent_activity_id: activity.id).where("period_start_date > ?", cut_off_quarter.end_date).any?
    end

    (definitely_active + potentially_active_due_to_actuals + potentially_active_due_to_forecasts).uniq
  end
end
