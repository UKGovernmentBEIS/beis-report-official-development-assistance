class Budget
  class Export
    HEADERS = [
      "RODA identifier",
      "Partner organisation identifier",
      "Partner organisation",
      "Level",
      "Title"
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

      activities.flat_map do |activity|
        activity_budgets = activity.budgets.to_a
        arr = []

        until activity_budgets.empty?
          arr << activity_data(activity) + budget_data(activity_budgets)
        end

        arr
      end
    end

    def filename
      [
        source_fund.short_name,
        @organisation&.beis_organisation_reference,
        "budgets.csv"
      ].reject(&:blank?).join("_")
    end

    private

    attr_reader :source_fund

    def activity_data(activity)
      [
        activity.roda_identifier,
        activity.partner_organisation_identifier,
        activity.extending_organisation&.name,
        I18n.t("table.body.activity.level.#{activity.level}"),
        activity.title
      ]
    end

    def budget_data(budgets)
      financial_year_range.map do |financial_year|
        budget_index = budgets.index { |budget| budget.financial_year == financial_year }
        value = budget_index.nil? ? 0 : budgets.delete_at(budget_index).value
        "%.2f" % value
      end
    end

    def activities
      @_activities ||= begin
        activities = @organisation.nil? ? Activity : Activity.where(extending_organisation: @organisation)
        activities.includes(:budgets, :extending_organisation).not_fund.where(source_fund_code: source_fund.id)
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
