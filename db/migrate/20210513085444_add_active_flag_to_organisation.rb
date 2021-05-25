class AddActiveFlagToOrganisation < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :active, :boolean, default: true
  end
end
