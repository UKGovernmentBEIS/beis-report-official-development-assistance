class AddReportIdToHistoricalEvent < ActiveRecord::Migration[6.1]
  def change
    add_reference :historical_events, :report, type: :uuid
  end
end
