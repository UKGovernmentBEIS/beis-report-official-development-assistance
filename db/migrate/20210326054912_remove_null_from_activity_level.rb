class RemoveNullFromActivityLevel < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:activities, :level, false)
  end
end
