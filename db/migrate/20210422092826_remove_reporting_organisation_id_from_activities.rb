class RemoveReportingOrganisationIdFromActivities < ActiveRecord::Migration[6.1]
  def change
    remove_reference :activities, :reporting_organisation, type: :uuid, foreign_key: {to_table: :organisations}
  end
end
