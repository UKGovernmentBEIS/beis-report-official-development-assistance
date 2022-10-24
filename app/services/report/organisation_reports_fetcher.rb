class Report
  class OrganisationReportsFetcher
    def initialize(organisation:)
      @organisation = organisation
    end

    def current
      @current ||= fetch(reports.not_approved)
    end

    def approved
      @approved ||= fetch(reports.approved)
    end

    private

    def reports
      return Report.where(organisation: organisation).not_ispf if ispf_in_stealth_mode_for_group?(:partner_organisation_users)
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
