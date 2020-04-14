class AddPreviousIdentifierToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :previous_identifier, :string
  end
end
