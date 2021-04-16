class RenameBeisIdToBeisIdentifier < ActiveRecord::Migration[6.1]
  def change
    rename_column :activities, :beis_id, :beis_identifier
  end
end
