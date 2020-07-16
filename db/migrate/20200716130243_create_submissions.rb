class CreateSubmissions < ActiveRecord::Migration[6.0]
  def change
    create_table :submissions, id: :uuid do |t|
      t.integer :state, default: 0, null: false
      t.string :description
      t.references :fund, type: :uuid
      t.references :organisation, type: :uuid
      t.timestamps
    end
  end
end
