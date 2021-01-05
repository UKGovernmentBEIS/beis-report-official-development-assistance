class RemoveFundingOrganisationFields < ActiveRecord::Migration[6.0]
  def up
    remove_column :activities, :funding_organisation_name, :string
    remove_column :activities, :funding_organisation_reference, :string
    remove_column :activities, :funding_organisation_type, :string
  end

  def down
    add_column :activities, :funding_organisation_name, :string, default: "Department for Business, Energy and Industrial Strategy"
    add_column :activities, :funding_organisation_reference, :string, default: "GB-GOV-13"
    add_column :activities, :funding_organisation_type, :string, default: "10"
  end
end
