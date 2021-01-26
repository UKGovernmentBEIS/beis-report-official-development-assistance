class CreateTransfer < ActiveRecord::Migration[6.0]
  def change
    create_table :transfers, id: :uuid do |t|
      t.references :source, foreign_key: {to_table: "activities", on_delete: :restrict}, type: :uuid, null: false
      t.references :destination, foreign_key: {to_table: "activities", on_delete: :restrict}, type: :uuid, null: false
      t.decimal :value, precision: 13, scale: 2, null: false
      t.date :date
    end
  end
end
