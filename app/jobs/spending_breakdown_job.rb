class SpendingBreakdownJob < ApplicationJob
  require "csv"

  def perform(requester_id:, fund_id:)
    requester = User.find(requester_id)
    fund = Fund.new(fund_id)

    export = Export::SpendingBreakdown.new(source_fund: fund)
    tempfile = save_tempfile(export)
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
end
