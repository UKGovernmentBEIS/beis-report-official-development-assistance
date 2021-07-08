class Activity
  class ProjectsForReportFinder
    def initialize(report:, scope: Activity.all)
      @report = report
      @scope = scope
    end

    def call
      scope.where(
        level: [:project, :third_party_project],
        organisation_id: report.organisation_id,
        source_fund_code: report.fund.source_fund_code
      )
    end

    private

    attr_reader :report, :scope
  end
end
