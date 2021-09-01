class AddInheritanceToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :type, :string
    add_index :transactions, :type
  end
end
