class AddProvidingOrganisationAssociationToBudget < ActiveRecord::Migration[6.0]
  def change
    add_reference :budgets, :providing_organisation, type: :uuid, foreign_key: {to_table: :organisations}
  end
end
