class AddLinkedActivityToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :linked_activity_id, :uuid
  end
end
