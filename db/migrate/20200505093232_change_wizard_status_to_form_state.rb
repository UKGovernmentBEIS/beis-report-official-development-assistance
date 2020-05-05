class ChangeWizardStatusToFormState < ActiveRecord::Migration[6.0]
  def up
    change_table :activities do |t|
      t.rename :wizard_status, :form_state
    end
  end

  def down
    change_table :activities do |t|
      t.rename :form_state, :wizard_status
    end
  end
end
