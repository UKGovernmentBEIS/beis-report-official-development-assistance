class AddServiceOwnerToOrganisations < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :service_owner, :boolean, default: false
  end
end
