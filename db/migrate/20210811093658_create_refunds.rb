class CreateRefunds < ActiveRecord::Migration[6.1]
  def change
    create_table :refunds, id: :uuid do |t|
      t.references :parent_activity, type: :uuid
      t.references :report, type: :uuid
      t.integer :financial_year
      t.integer :financial_quarter
      t.decimal :value, precision: 13, scale: 2
      t.text :comment

      t.timestamps
    end
  end
end
