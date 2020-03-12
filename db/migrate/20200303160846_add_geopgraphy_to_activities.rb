class AddGeopgraphyToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :geography, :string
  end
end
