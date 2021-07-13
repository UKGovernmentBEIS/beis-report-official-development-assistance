# Run me with `rails runner db/data/20210712154227_remove_historical_events_for_wizard_form_state_changes.rb`

HistoricalEvent.where(value_changed: "form_state").destroy_all
