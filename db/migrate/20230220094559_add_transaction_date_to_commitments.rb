class AddTransactionDateToCommitments < ActiveRecord::Migration[6.1]
  def change
    add_column :commitments, :transaction_date, :date
  end
end
