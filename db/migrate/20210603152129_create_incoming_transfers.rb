class CreateIncomingTransfers < ActiveRecord::Migration[6.1]
  def change
    create_table :incoming_transfers, id: :uuid do |t|
      t.references :source, foreign_key: {to_table: "activities", on_delete: :restrict}, type: :uuid, null: false
      t.references :destination, foreign_key: {to_table: "activities", on_delete: :restrict}, type: :uuid, null: false
      t.references :report, type: :uuid
      t.decimal :value, precision: 13, scale: 2, null: false
      t.integer :financial_year
      t.integer :financial_quarter

      t.timestamps
    end
  end
end
