class SpendingBreakdownJob < ApplicationJob
  require "csv"

  def perform(requester_id:, fund_id:)
    requester = User.find(requester_id)
    fund = Fund.new(fund_id)
    export = Export::SpendingBreakdown.new(source_fund: fund)
    tempfile = save_tempfile(export)
    download_url = upload_csv_to_s3(tempfile)
    DownloadLinkMailer.send_link(
      recipient: requester,
      file_url: download_url,
      file_name: export.filename
    ).deliver
  end

  def save_tempfile(export)
    tmpfile = Tempfile.new
    CSV.open(tmpfile, "wb", {headers: true}) do |csv|
      csv << export.headers
      export.rows.each do |row|
        csv << row
      end
    end
    tmpfile
  end

  def upload_csv_to_s3(file)
    uploader = Export::S3Uploader.new(file)
    file_url = uploader.upload
    file_url
  end
end
