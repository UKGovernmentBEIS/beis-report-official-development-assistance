class ChangeDefaultReportStateToActive < ActiveRecord::Migration[6.1]
  def up
    change_column :reports, :state, :string, default: "active"
  end

  def down
    change_column :reports, :state, :string, default: "inactive"
  end
end
