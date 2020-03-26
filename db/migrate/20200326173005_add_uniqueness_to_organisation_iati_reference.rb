class AddUniquenessToOrganisationIatiReference < ActiveRecord::Migration[6.0]
  def change
    add_index :organisations, :iati_reference, unique: true
  end
end
