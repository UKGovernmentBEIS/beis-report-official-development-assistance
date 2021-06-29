class ChangeGcrfStrategicAreaToString < ActiveRecord::Migration[6.1]
  def up
    change_column :activities, :gcrf_strategic_area, :string, using: "CAST(gcrf_strategic_area AS varchar[])", array: true, default: []
  end

  def down
    change_column :activities, :gcrf_strategic_area, :integer, using: "CAST(gcrf_strategic_area AS integer[])", array: true, default: []
  end
end
