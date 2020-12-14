class TransactionsReflectActualDisbursements < ActiveRecord::Migration[6.0]
  def up
    Transaction.where(transaction_type: [2, 11]).delete_all
    Transaction.where(transaction_type: [4, 10]).update_all(transaction_type: 3)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
