class AddHasLinkedActivityToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :has_linked_activity, :integer
  end
end
