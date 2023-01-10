module ReportHelper
  def report_download_link(report)
    return download_report_path(report) if report.export_filename

    report_path(report, format: :csv)
  end
end
