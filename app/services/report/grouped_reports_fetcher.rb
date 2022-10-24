class Report
  class GroupedReportsFetcher
    def current
      @current ||= fetch(reports.not_approved)
    end

    def approved
      @approved ||= fetch(reports.approved)
    end

    private def reports
      return Report.not_ispf if ispf_in_stealth_mode_for_group?(:beis_users)

      Report
    end

    private def fetch(relation)
      relation
        .includes([:organisation, :fund])
        .order("organisations.name ASC, financial_year, financial_quarter DESC")
        .map { |report| ReportPresenter.new(report) }
        .group_by(&:organisation)
    end
  end
end
