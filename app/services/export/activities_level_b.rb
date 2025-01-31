class Export::ActivitiesLevelB
  HEADERS = [
    "Partner Organisation",
    "Activity level",
    "Parent activity",
    "ODA or Non-ODA",
    "Partner organisation identifier",
    "RODA identifier",
    "IATI identifier",
    "Linked activity",
    "Activity title",
    "Activity description",
    "Aims or objectives",
    "Sector",
    "Original commitment figure",
    "Activity status",
    "Planned start date",
    "Planned end date",
    "Actual start date",
    "Actual end date",
    "ISPF ODA partner countries",
    "Benefitting countries",
    "Benefitting region",
    "Global Development Impact",
    "Sustainable Development Goals",
    "ISPF themes",
    "Aid type",
    "ODA eligibility",
    "Publish to IATI?",
    "Tags",
    "Budget 2023-2024",
    "Budget 2024-2025",
    "Budget 2025-2026",
    "Budget 2026-2027",
    "Budget 2027-2028",
    "Budget 2028-2029",
    "Comments"
  ].freeze

  def initialize(fund:)
    @fund = fund
  end

  def headers
    HEADERS
  end

  def filename
    "LevelB_#{@fund.name.tr(" ", "_")}_#{Time.zone.now.strftime("%Y-%m-%d_%H-%M-%S")}.csv"
  end

  def rows
    activities.map do |activity|
      row_for(activity)
    end
  end

  private

  def row_for(activity)
    activity = ActivityCsvPresenter.new(activity)
    budgets_by_year = activity.budgets.each_with_object({}) do |budget, hash|
      hash[budget.financial_year.start_year] = BudgetPresenter.new(budget)
    end
    [
      activity.organisation.name,               # "Partner Organisation",
      activity.level,                           # "Activity level",
      @fund.name,                               # "Parent activity",
      activity.is_oda,                          # "ODA or Non-ODA",
      activity.partner_organisation_identifier, # "Partner organisation identifier",
      activity.roda_identifier,                 # "RODA identifier", e.g. GCRF-LCXHF
      activity.transparency_identifier,         # "IATI identifier",
      activity.linked_activity_identifier,      # "Linked activity",
      activity.title,                           # "Activity title",
      activity.description,                     # "Activity description",
      activity.objectives,                      # "Aims or objectives",
      activity.sector,                          # "Sector",
      activity.commitment&.value,               # "Original commitment figure",
      activity.programme_status,                # "Activity status",
      activity.planned_start_date,              # "Planned start date",
      activity.planned_end_date,                # "Planned end date",
      activity.actual_start_date,               # "Actual start date",
      activity.actual_end_date,                 # "Actual end date",
      activity.ispf_oda_partner_countries,      # "ISPF ODA partner countries",
      activity.benefitting_countries,           # "Benefitting countries",
      activity.benefitting_region,              # "Benefitting region",
      activity.gdi,                             # "Global Development Impact",
      activity.sustainable_development_goals,   # "Sustainable Development Goals",
      activity.ispf_themes,                     # "ISPF themes",
      activity.aid_type,                        # "Aid type",
      activity.oda_eligibility,                 # "ODA eligibility",
      activity.publish_to_iati,                 # "Publish to IATI?",
      activity.tags,                            # "Tags",
      budgets_by_year[2023]&.value,             # "Budget 2023-2024",
      budgets_by_year[2024]&.value,             # "Budget 2024-2025",
      budgets_by_year[2025]&.value,             # "Budget 2025-2026",
      budgets_by_year[2026]&.value,             # "Budget 2026-2027",
      budgets_by_year[2027]&.value,             # "Budget 2027-2028",
      budgets_by_year[2028]&.value,             # "Budget 2028-2029",
      activity.comments.map(&:body).join("\n")  # "Comments"
    ]
  end

  def activities
    @activities ||= @fund.activity.child_activities
      .includes(:organisation, :linked_activity, :commitment, :budgets, :comments)
  end
end
