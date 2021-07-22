class RemoveRodaIdentifierFragmentFromActivity < ActiveRecord::Migration[6.1]
  def change
    remove_column :activities, :roda_identifier_fragment, :string
  end
end
