RSpec::Matchers.define :create_a_historical_forecast_event do |args|
  match(notify_expectation_failures: true) do |actual|
    expect { actual.call }.to change { HistoricalEvent.count }.by(1)

    historical_event =
      HistoricalEvent.order(:created_at).last
    forecast =
      Forecast.unscoped.where(parent_activity_id: args[:activity].id).order(:created_at).last

    expect(historical_event.reference).to eq("Revising a forecast for #{args[:financial_quarter]}")
    expect(historical_event.user).to eq(user)
    expect(historical_event.activity).to eq(args[:activity])
    expect(historical_event.trackable_id).to eq(forecast.id)
    expect(historical_event.report).to eq(args[:report])
    expect(historical_event.value_changed).to eq("value")
    expect(historical_event.previous_value).to eq(args[:previous_value])
    expect(historical_event.new_value).to eq(args[:new_value])
  end

  supports_block_expectations
end

RSpec::Matchers.define :not_create_a_historical_event do |args|
  match(notify_expectation_failures: true) do |actual|
    expect { actual.call }.to change { HistoricalEvent.count }.by(0)
  end

  supports_block_expectations
end
