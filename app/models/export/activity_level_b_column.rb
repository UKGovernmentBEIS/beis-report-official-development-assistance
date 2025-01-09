class Export::ActivityLevelBColumn
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
    [
      headers.map { "placeholder" },
      headers.map { "placeholder2" }
    ]
  end
end
