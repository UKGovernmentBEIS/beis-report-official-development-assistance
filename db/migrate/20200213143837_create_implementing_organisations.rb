class CreateImplementingOrganisations < ActiveRecord::Migration[6.0]
  def change
    create_table :implementing_organisations, id: :uuid do |t|
      t.string :name
      t.string :reference
      t.string :organisation_type
      t.references :activity, type: :uuid
      t.timestamps
    end
  end
end
