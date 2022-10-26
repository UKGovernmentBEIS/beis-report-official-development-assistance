class AddIsOdaToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :is_oda, :boolean
  end
end
