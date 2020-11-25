class AddSdgsApplyToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :sdgs_apply, :boolean, default: false, null: false
  end
end
