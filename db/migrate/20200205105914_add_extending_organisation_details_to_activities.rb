class AddExtendingOrganisationDetailsToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.string :extending_organisation_name
      t.string :extending_organisation_reference
      t.string :extending_organisation_type
    end
  end
end
