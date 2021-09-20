class Budget
  class Export
    HEADERS = [
      "RODA identifier",
      "Delivery partner identifier",
      "Level",
      "Title",
    ]

    def initialize(source_fund:, organisation: nil)
      @source_fund = source_fund
      @organisation = organisation
    end

    def headers
      return HEADERS if budgets.empty?

      HEADERS + financial_year_range.map(&:to_s)
    end

    def rows
      return [] if budgets.empty?

      activities.map do |activity|
        activity_data(activity) + budget_data(activity.budgets)
      end
    end

    def filename
      [
        source_fund.short_name,
        @organisation&.beis_organisation_reference,
        "budgets.csv",
      ].reject(&:blank?).join("_")
    end

    private

    attr_reader :source_fund

    def activity_data(activity)
      [
        activity.roda_identifier,
        activity.delivery_partner_identifier,
        I18n.t("table.body.activity.level.#{activity.level}"),
        activity.title,
      ]
    end

    def budget_data(budgets)
      financial_year_range.map do |financial_year|
        value = budgets.find { |budget| budget.financial_year == financial_year }&.value || 0
        "%.2f" % value
      end
    end

    def activities
      @_activities ||= begin
        activities = @organisation.nil? ? Activity : Activity.where(extending_organisation: @organisation)
        activities.includes(:budgets).not_fund.where(source_fund_code: source_fund.id)
      end
    end

    def budgets
      @_budgets ||= activities.map(&:budgets).flatten.uniq
    end

    def financial_years
      budgets.map(&:financial_year).uniq
    end

    def financial_year_range
      @_financial_year_range ||= Range.new(*financial_years.minmax)
    end
  end
end
