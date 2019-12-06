class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string :reference
      t.text :description
      t.string :transaction_type
      t.date :date
      t.decimal :value, precision: 7, scale: 2
      t.string :disbursement_channel
      t.string :currency
      t.references :fund, type: :uuid
      t.timestamps
    end
  end
end
