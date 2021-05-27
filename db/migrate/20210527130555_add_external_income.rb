class AddExternalIncome < ActiveRecord::Migration[6.1]
  def change
    create_table :external_incomes, id: :uuid do |t|
      t.belongs_to :activity, type: :uuid
      t.belongs_to :organisation, type: :uuid
      t.decimal :amount, precision: 13, scale: 2
      t.integer :financial_quarter
      t.integer :financial_year
      t.boolean :oda_funding

      t.timestamps
    end
  end
end
