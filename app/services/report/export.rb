class Report
  class Export
    def initialize(report:)
      @report = report
    end

    def headers
      ExportActivityToCsv.new(report: @report).headers
    end

    def rows
      activities.map do |activity|
        ExportActivityToCsv.new(activity: activity, report: report).call
      end
    end

    def filename
      report_presenter.filename_for_report_download
    end

    private

    attr_reader :report

    def activities
      @activities ||= Activity::ProjectsForReportFinder.new(report: report).call
    end

    def report_presenter
      @report_presenter ||= ReportPresenter.new(report)
    end
  end
end
