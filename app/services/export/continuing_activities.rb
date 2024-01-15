class Export::ContinuingActivities
  def filename
    "continuing_activities.csv"
  end

  def non_continuing_filename
    "non_continuing_activities.csv"
  end

  def headers
    [
      "Partner Organisation name",
      "Activity title",
      "Activity RODA ID",
      "Fund (level A)",
      "Parent level B RODA ID",
      "Parent level B title",
      "Current Transparency identifier",
      "Future Transparency identifier",
      "Current Previous identifier",
      "Future Previous identifier",
      "Partner Organisation ID",
      "Status",
      "Level"
    ]
  end

  def non_continuing_headers
    [
      "Partner Organisation name",
      "Activity title",
      "Activity RODA ID",
      "Fund (level A)",
      "Parent level B RODA ID",
      "Parent level B title",
      "Transparency identifier",
      "Previous identifier",
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
      fund = activity.associated_fund.roda_identifier
      parent_level_b_roda_id = case activity.level
      when "programme"
        ""
      when "project"
        activity.parent.roda_identifier
      else
        activity.parent.parent.roda_identifier
      end
      parent_level_b_title = case activity.level
      when "programme"
        ""
      when "project"
        activity.parent.title
      else
        activity.parent.parent.title
      end
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
        fund,
        parent_level_b_roda_id,
        parent_level_b_title,
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
    @_activities ||= begin
      # active statuses, regardless of any associated actual spend
      definitely_active = Activity
        .joins(:organisation)
        .includes(:organisation, :parent)
        .where.not(level: "fund")
        .where(is_oda: [nil, true])
        .where.not(programme_status: ["completed", "stopped", "cancelled", "finalisation", "paused"])
        .order("organisations.name, activities.roda_identifier")

      cut_off_quarter = FinancialQuarter.new(2022, 4)

      # activities that MAY need to continue, IF they have actual spend more recent than FQ4 2022-2023
      potentially_active_due_to_actuals = Activity
        .joins(:organisation, :actuals)
        .includes(:organisation, :parent)
        .where.not(level: "fund")
        .where(is_oda: [nil, true])
        .where(programme_status: ["completed", "stopped", "cancelled", "finalisation", "paused"])
        .where("transactions.date > ?", cut_off_quarter.end_date)
        .order("organisations.name, activities.roda_identifier")

      # activities that MAY need to continue, IF they have forecasts for quarters after FQ4 2022-2023
      potentially_active_due_to_forecasts = Activity
        .joins(:organisation)
        .includes(:organisation, :parent)
        .where.not(level: "fund")
        .where(is_oda: [nil, true])
        .where(programme_status: "paused")
        .order("organisations.name, activities.roda_identifier")
      potentially_active_due_to_forecasts = potentially_active_due_to_forecasts.select do |activity|
        Forecast.unscoped.where(parent_activity_id: activity.id).where("period_start_date > ?", cut_off_quarter.end_date).any?
      end

      (definitely_active + potentially_active_due_to_actuals + potentially_active_due_to_forecasts).uniq
    end
  end

  def non_continuing_rows
    non_continuing_activities = Activity
      .where.not(level: "fund")
      .where.not(id: activities.pluck(:id))
      .where(is_oda: [true, nil])
    non_continuing_activities.map do |activity|
      partner_organisation_name = activity.organisation.name
      activity_title = activity.title || "Untitled (#{activity.id})"
      roda_identifier = activity.roda_identifier
      fund = activity.associated_fund.roda_identifier
      parent_level_b_roda_id = case activity.level
      when "programme"
        ""
      when "project"
        activity.parent&.roda_identifier
      else
        activity.parent&.parent&.roda_identifier
      end
      parent_level_b_title = case activity.level
      when "programme"
        ""
      when "project"
        activity.parent&.title
      else
        activity.parent&.parent&.title
      end
      transparency_identifier = activity.transparency_identifier
      previous_identifier = activity.previous_identifier
      partner_organisation_identifier = activity.partner_organisation_identifier
      status = activity.programme_status ? I18n.t("activity.programme_status.#{activity.programme_status}") : ""
      level = I18n.t("table.body.activity.level.#{activity.level}")

      [
        partner_organisation_name,
        activity_title,
        roda_identifier,
        fund,
        parent_level_b_roda_id,
        parent_level_b_title,
        transparency_identifier,
        previous_identifier,
        partner_organisation_identifier,
        status,
        level
      ]
    end
  end
end
