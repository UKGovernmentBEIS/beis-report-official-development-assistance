class RemoveExtendingOrganisationFromActivities < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :extending_organisation_name
    remove_column :activities, :extending_organisation_reference
    remove_column :activities, :extending_organisation_type
  end
end
