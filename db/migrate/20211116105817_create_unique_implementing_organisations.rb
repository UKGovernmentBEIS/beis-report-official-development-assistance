class CreateUniqueImplementingOrganisations < ActiveRecord::Migration[6.1]
  def change
    create_table :unique_implementing_organisations, id: :uuid do |t|
      t.string :name
      t.string :legacy_names, array: true
      t.string :reference
      t.string :organisation_type
      t.timestamps
    end
  end
end
