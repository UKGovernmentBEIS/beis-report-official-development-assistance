class CreateOrganisations < ActiveRecord::Migration[6.0]
  def change
    create_table :organisations, id: :uuid do |t|
      t.string :name
      t.string :organisation_type
      t.string :language_code
      t.string :default_currency
      t.timestamps
    end
  end
end
