class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments, id: :uuid do |t|
      t.text :comment
      t.references :owner, type: :uuid
      t.references :activity, type: :uuid
      t.references :report, type: :uuid
      t.timestamps
    end
  end
end
