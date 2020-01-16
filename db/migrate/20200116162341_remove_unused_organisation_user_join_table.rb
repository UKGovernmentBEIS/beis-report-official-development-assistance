class RemoveUnusedOrganisationUserJoinTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :organisations_users
  end
end
