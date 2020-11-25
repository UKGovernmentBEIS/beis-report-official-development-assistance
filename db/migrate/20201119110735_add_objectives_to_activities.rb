class AddObjectivesToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :objectives, :text
  end
end
