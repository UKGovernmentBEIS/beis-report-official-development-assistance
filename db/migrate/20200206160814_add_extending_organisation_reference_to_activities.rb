class AddExtendingOrganisationReferenceToActivities < ActiveRecord::Migration[6.0]
  def change
    add_reference :activities, :extending_organisation, type: :uuid, foreign_key: {to_table: :organisations}
  end
end
