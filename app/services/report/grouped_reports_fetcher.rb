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
        .order("organisations.name ASC, activities.created_at ASC, reports.is_oda DESC, financial_year DESC, financial_quarter DESC")
        .map { |report| ReportPresenter.new(report) }
        .group_by(&:organisation)
    end
  end
end
