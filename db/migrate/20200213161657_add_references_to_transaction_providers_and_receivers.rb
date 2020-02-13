class AddReferencesToTransactionProvidersAndReceivers < ActiveRecord::Migration[6.0]
  def change
    change_table :transactions do |t|
      t.string :providing_organisation_reference
      t.string :receiving_organisation_reference
    end
  end
end
