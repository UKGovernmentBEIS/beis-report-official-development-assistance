class ChangeWizardStepForAllActivitiesWithoutIdentifierToBlank < ActiveRecord::Migration[6.0]
  def up
    activities = Activity.where(wizard_status: :identifier, identifier: nil)
    activities.update_all(wizard_status: :blank)
  end

  def down
    activities = Activity.where(wizard_status: :blank, identifier: nil)
    activities.update_all(wizard_status: :identifier)
  end
end
