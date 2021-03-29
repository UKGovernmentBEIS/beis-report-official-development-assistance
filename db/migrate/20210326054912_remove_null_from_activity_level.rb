class RemoveNullFromActivityLevel < ActiveRecord::Migration[6.0]
  def up
    Activity.where(level: nil).destroy_all

    change_column_null(:activities, :level, false)
  end

  def down
    change_column_null(:activities, :level, true)
  end
end
