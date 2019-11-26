class CreateFunds < ActiveRecord::Migration[6.0]
  def change
    create_table :funds, id: :uuid do |t|
      t.string :name
      t.references :organisation, type: :uuid
      t.timestamps
    end
  end
end
