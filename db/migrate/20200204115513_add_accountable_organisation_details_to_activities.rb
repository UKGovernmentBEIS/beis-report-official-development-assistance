class AddAccountableOrganisationDetailsToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.string :accountable_organisation_name
      t.string :accountable_organisation_reference
      t.string :accountable_organisation_type
    end
  end
end
