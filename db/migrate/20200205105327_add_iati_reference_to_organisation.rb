class AddIatiReferenceToOrganisation < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :iati_reference, :string
  end
end
