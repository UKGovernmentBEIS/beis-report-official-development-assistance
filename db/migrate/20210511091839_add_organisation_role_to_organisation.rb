class AddOrganisationRoleToOrganisation < ActiveRecord::Migration[6.1]
  def up
    add_column :organisations, :role, :integer

    Organisation.where(service_owner: true).update_all(role: 99)
    Organisation.where(service_owner: false).update_all(role: 0)
  end

  def down
    Organisation.where(role: 99).update_all(service_owner: true)
    Organisation.where.not(role: 99).update_all(service_owner: false)

    remove_column :organisations, :role
  end
end
