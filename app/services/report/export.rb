class Report
  class Export
    def initialize(reports:, export_type: :single)
      @reports = reports
      @export_type = export_type
    end

    def headers
      ExportActivityToCsv.new(report: reports.first).headers
    end

    def rows
      reports.flat_map { |report|
        activities_for_report(report).map do |activity|
          ExportActivityToCsv.new(activity: activity, report: report).call
        end
      }
    end

    def filename
      if export_type == :single
        report_presenter.filename_for_report_download
      else
        report_presenter.filename_for_all_reports_download
      end
    end

    private

    attr_reader :reports, :export_type

    def activities_for_report(report)
      Activity::ProjectsForReportFinder.new(
        report: report,
        scope: scope
      ).call.sort_by { |a| a.level }
    end

    def report_presenter
      @report_presenter ||= ReportPresenter.new(reports.first)
    end

    def scope
      export_type == :single ? Activity.all : Activity.includes(:organisation, :extending_organisation, :implementing_organisations)
    end
  end
end
