class AddProviderAndReceiverFieldsToTransaction < ActiveRecord::Migration[6.0]
  def change
    change_table :transactions do |t|
      t.string :providing_organisation_name
      t.string :providing_organisation_type
      t.string :receiving_organisation_name
      t.string :receiving_organisation_type
    end
  end
end
