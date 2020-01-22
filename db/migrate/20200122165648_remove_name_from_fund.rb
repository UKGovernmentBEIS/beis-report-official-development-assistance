class RemoveNameFromFund < ActiveRecord::Migration[6.0]
  def change
    remove_column :funds, :name
  end
end
