class AddReporterReferenceToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :reporting_organisation_reference, :string
  end
end
