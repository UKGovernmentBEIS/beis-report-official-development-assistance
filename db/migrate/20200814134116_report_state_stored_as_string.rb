class ReportStateStoredAsString < ActiveRecord::Migration[6.0]
  def change
    change_column :reports, :state, :string, default: "inactive"
    add_index :reports, :state
  end
end
