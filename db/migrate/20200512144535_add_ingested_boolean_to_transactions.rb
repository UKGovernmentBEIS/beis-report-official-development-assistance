class AddIngestedBooleanToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :ingested, :boolean, default: false
  end
end
