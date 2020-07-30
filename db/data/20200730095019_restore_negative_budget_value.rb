class RestoreNegativeBudgetValue < ActiveRecord::Migration[6.0]
  def up
    activity = Activity.find_by(previous_identifier: "GB-GOV-13-NEWT-RS_BRA_797")

    Budget.find_by(parent_activity: activity, period_start_date: "2015-10-01", value: "0.01")&.update!(value: "-3920.71")
  end

  def down
    activity = Activity.find_by(previous_identifier: "GB-GOV-13-NEWT-RS_BRA_797")

    Budget.find_by(parent_activity: activity, period_start_date: "2015-10-01", value: "-3920.71")&.update!(value: "0.01")
  end
end
