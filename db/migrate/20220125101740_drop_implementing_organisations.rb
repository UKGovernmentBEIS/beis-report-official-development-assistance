class DropImplementingOrganisations < ActiveRecord::Migration[6.1]
  def change
    drop_table :implementing_organisations
  end
end
