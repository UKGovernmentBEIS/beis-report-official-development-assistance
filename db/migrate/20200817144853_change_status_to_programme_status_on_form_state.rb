class ChangeStatusToProgrammeStatusOnFormState < ActiveRecord::Migration[6.0]
  def up
    Activity.where(form_state: "status").update_all(form_state: "programme_status")
  end

  def down
    Activity.where(form_state: "programme_status").update_all(form_state: "status")
  end
end
