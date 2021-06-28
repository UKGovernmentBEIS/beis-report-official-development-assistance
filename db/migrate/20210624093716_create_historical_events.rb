class CreateHistoricalEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :historical_events, id: :uuid do |t|
      t.references :user, type: :uuid
      t.references :activity, type: :uuid
      t.text :value_changed
      t.text :new_value
      t.text :previous_value
      t.text :reference

      t.timestamps
    end
  end
end
