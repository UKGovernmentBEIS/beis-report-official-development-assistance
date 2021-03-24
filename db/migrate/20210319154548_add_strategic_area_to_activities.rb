class AddStrategicAreaToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :gcrf_strategic_area, :string, array: true
  end
end
