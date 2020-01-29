class AddLevelToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.string :level
      t.index :level
    end
  end
end
