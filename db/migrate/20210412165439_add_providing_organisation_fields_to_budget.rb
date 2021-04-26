class AddProvidingOrganisationFieldsToBudget < ActiveRecord::Migration[6.0]
  def change
    change_table :budgets do |t|
      t.string :providing_organisation_name
      t.string :providing_organisation_type
      t.string :providing_organisation_reference
    end
  end
end
