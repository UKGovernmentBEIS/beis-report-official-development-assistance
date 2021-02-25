class AddBeisOrganisationReferenceToOrganisations < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :beis_organisation_reference, :string
  end
end
