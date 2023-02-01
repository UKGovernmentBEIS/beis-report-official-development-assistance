class SpendingBreakdownJob < ApplicationJob
  require "csv"

  def perform(requester_id:, fund_id:)
    requester = User.find(requester_id)
    source_fund = Fund.new(fund_id)

    export = Export::SpendingBreakdown.new(source_fund: source_fund)
    upload = upload_csv_to_s3(file: save_tempfile(export), filename: export.filename)

    fund_activity = source_fund.activity
    fund_activity.spending_breakdown_filename = upload.timestamped_filename
    fund_activity.save!

    DownloadLinkMailer.send_link(
      recipient: requester,
      file_name: upload.timestamped_filename
    ).deliver
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
    Export::S3Uploader.new(file: file, filename: filename, use_public_bucket: true).upload
  end

  def log_error(error, requester)
    message = "#{error.message} for #{requester.email}"
    Rails.logger.error(message)
    Rollbar.log(:error, message, error)
  end
end
