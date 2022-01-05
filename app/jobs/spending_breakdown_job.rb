class SpendingBreakdownJob < ApplicationJob
  require "csv"

  def perform(requester_id:, fund_id:)
    requester = User.find(requester_id)

    export = Export::SpendingBreakdown.new(source_fund: Fund.new(fund_id))
    tempfile = save_tempfile(export)

    DownloadLinkMailer.send_link(
      recipient: requester,
      file_url: upload_csv_to_s3(tempfile),
      file_name: export.filename
    ).deliver
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

  def upload_csv_to_s3(file)
    Export::S3Uploader.new(file).upload
  end
end
