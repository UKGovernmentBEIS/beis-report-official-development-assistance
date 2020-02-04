class AddFundingOrganisationDetailsToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.string :funding_organisation_name
      t.string :funding_organisation_reference
      t.string :funding_organisation_type
    end
  end
end
