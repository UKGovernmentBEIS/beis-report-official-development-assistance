class RemoveServiceOwnerBooleanFromOrganisation < ActiveRecord::Migration[6.1]
  def change
    remove_column :organisations, :service_owner, :boolean
  end
end
