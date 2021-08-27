class Report
  class OrganisationReportsFetcher
    def initialize(organisation:)
      @organisation = organisation
    end

    def current
      @current ||= fetch(reports.not_approved.not_inactive)
    end

    def approved
      @approved ||= fetch(reports.approved)
    end

    private

    def reports
      Report.where(organisation: organisation)
    end

    private def fetch(relation)
      relation
        .includes([:organisation, :fund])
        .order("financial_year, financial_quarter DESC")
        .map { |report| ReportPresenter.new(report) }
    end

    attr_reader :organisation
  end
end
