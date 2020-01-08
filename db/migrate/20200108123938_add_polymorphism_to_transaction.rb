class AddPolymorphismToTransaction < ActiveRecord::Migration[6.0]
  def change
    rename_column :transactions, :fund_id, :hierarchy_id
    remove_index :transactions, :hierarchy_id
    add_column :transactions, :hierarchy_type, :string
    add_index :transactions, [:hierarchy_id, :hierarchy_type]
    Transaction.update_all(hierarchy_type: "Fund")
  end
end
