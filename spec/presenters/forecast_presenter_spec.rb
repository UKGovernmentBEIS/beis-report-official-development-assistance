require "rails_helper"

RSpec.describe ForecastPresenter do
  let(:forecast) { Forecast.unscoped.new(value: 100_000) }

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(forecast).value).to eq("£100,000.00")
    end
  end
end
