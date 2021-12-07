class AddAlternateNamesToOrganisation < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :alternate_names, :string, array: true
  end
end
