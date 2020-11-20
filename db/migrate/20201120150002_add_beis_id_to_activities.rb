class AddBeisIdToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :beis_id, :string
  end
end
