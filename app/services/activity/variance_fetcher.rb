class Activity
  class VarianceFetcher
    attr_reader :report

    def initialize(report)
      @report = report
    end

    def activities
      activities_with_variance.map { |activity| ActivityPresenter.new(activity) }
    end

    def total
      activities_with_variance.sum { |a| a.variance_for_report_financial_quarter(report: report) }
    end

    private

    def activities_with_variance
      @activities_with_variance ||= begin
        all_activities_for_report.reject { |activity|
          activity.variance_for_report_financial_quarter(report: report).zero?
        }
      end
    end

    def all_activities_for_report
      Activity::ProjectsForReportFinder.new(
        scope: Activity.includes(:organisation),
        report: report
      ).call
    end
  end
end
