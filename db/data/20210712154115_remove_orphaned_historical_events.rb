# Run me with `rails runner db/data/20210712154115_remove_orphaned_historical_events.rb`
#
orphaned_events = HistoricalEvent.all.select { |event| Activity.find_by(id: event.activity_id).nil? }
orphaned_events.destroy_all
