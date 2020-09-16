class AddCollaborationTypeToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :collaboration_type, :string
  end
end
