class AddMatchedEffort < ActiveRecord::Migration[6.1]
  def change
    create_table :matched_efforts, id: :uuid do |t|
      t.belongs_to :activity, type: :uuid
      t.belongs_to :organisation, type: :uuid
      t.integer :funding_type
      t.integer :category
      t.decimal :committed_amount, precision: 13, scale: 2
      t.string :currency
      t.decimal :exchange_rate, precision: 14, scale: 12
      t.date :date_of_exchange_rate
      t.text :notes

      t.timestamps
    end
  end
end
