class ChangeRodaIdentifierCompoundToRodaIdentifier < ActiveRecord::Migration[6.1]
  def change
    rename_column :activities, :roda_identifier_compound, :roda_identifier
  end
end
