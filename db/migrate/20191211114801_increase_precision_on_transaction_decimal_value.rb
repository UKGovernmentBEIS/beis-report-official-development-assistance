class IncreasePrecisionOnTransactionDecimalValue < ActiveRecord::Migration[6.0]
  def up
    change_column :transactions, :value, :decimal, precision: 13, scale: 2
  end

  def down
    change_column :transactions, :value, :decimal, precision: 7, scale: 2
  end
end
