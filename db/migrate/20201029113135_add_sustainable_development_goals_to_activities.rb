class AddSustainableDevelopmentGoalsToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :sdg_1, :integer
    add_column :activities, :sdg_2, :integer
    add_column :activities, :sdg_3, :integer
  end
end
