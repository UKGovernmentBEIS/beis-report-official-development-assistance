class ReportExportUploaderJob < ApplicationJob
  require "csv"

  def perform(requester_id:, report_id:)
    requester = User.find(requester_id)
    report = Report.find(report_id)

    export = Export::Report.new(report: report)
    upload = upload_csv_to_s3(file: save_tempfile(export), filename: export.filename)
    report.export_filename = upload.timestamped_filename
    report.save
  rescue => error
    log_error(error, requester)
    DownloadLinkMailer.send_failure_notification(recipient: requester).deliver
  end

  def save_tempfile(export)
    Tempfile.new.tap do |tmpfile|
      CSV.open(tmpfile, "wb", {headers: true}) do |csv|
        csv << export.headers
        export.rows.each do |row|
          csv << row
        end
      end
    end
  end

  def upload_csv_to_s3(file:, filename:)
    Export::S3Uploader.new(file: file, filename: filename, use_public_bucket: false).upload
  end

  def log_error(error, requester)
    message = "#{error.message} for #{requester.email}"
    Rails.logger.error(message)
    Rollbar.log(:error, message, error)
  end
end
