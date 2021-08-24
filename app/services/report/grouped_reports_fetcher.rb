class Report
  class GroupedReportsFetcher
    def current
      @current ||= fetch(Report.not_approved)
    end

    def approved
      @approved ||= fetch(Report.approved)
    end

    private def fetch(relation)
      relation
        .includes([:organisation, :fund])
        .order("financial_year, financial_quarter DESC")
        .map { |report| ReportPresenter.new(report) }
        .group_by(&:organisation)
    end
  end
end
