class AddCommitment < ActiveRecord::Migration[6.1]
  def change
    create_table :commitments, id: :uuid do |t|
      t.decimal :value, precision: 13, scale: 2
      t.references :activity, type: :uuid, index: {unique: true}
      t.timestamps
    end
  end
end
