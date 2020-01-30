class AddOrganisationToUserDirectlyRatherThanJoin < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :organisation, index: true, type: :uuid
  end
end
