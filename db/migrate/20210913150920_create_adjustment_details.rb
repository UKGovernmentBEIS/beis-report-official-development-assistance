class CreateAdjustmentDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :adjustment_details, id: :uuid do |t|
      t.uuid :adjustment_id
      t.uuid :user_id
      t.string :adjustment_type

      t.timestamps
    end
    add_index :adjustment_details, :adjustment_id
    add_index :adjustment_details, :user_id
    add_index :adjustment_details, :adjustment_type
  end
end
