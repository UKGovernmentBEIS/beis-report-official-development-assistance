class AddProgrammeStatusToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :programme_status, :string
  end
end
