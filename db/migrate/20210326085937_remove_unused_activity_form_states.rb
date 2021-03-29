class RemoveUnusedActivityFormStates < ActiveRecord::Migration[6.0]
  def up
    Activity.where(form_state: [nil, :blank, :level, :parent]).destroy_all

    change_column_null(:activities, :form_state, false)
  end

  def down
    change_column_null(:activities, :form_state, true)
  end
end
