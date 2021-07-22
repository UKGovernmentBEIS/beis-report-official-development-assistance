class MakeHistoricalEventPolymorphic < ActiveRecord::Migration[6.1]
  def change
    change_table :historical_events do |t|
      t.string :trackable_id
      t.string :trackable_type
    end
    add_index :historical_events, [:trackable_type, :trackable_id]

    HistoricalEvent.all.each do |event|
      event.update_columns(trackable_id: event.activity_id, trackable_type: "Activity")
    end
  end
end
