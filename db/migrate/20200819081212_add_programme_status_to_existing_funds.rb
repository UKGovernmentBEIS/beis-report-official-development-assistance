class AddProgrammeStatusToExistingFunds < ActiveRecord::Migration[6.0]
  def up
    Activity.where(level: "fund", programme_status: nil).update_all(programme_status: "06")
  end
end
