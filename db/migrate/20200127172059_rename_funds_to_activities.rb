class RenameFundsToActivities < ActiveRecord::Migration[6.0]
  def self.up
    rename_table :funds, :activities
  end

  def self.down
    rename_table :activities, :funds
  end
end
