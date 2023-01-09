module ReportHelper
  def report_download_link(report)
    return report.export_url if report.export_url

    report_path(report, format: :csv)
  end
end
