class AddWizardStatusToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column(:activities, :wizard_status, :string)
  end
end
