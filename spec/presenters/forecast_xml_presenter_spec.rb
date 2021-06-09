require "rails_helper"

RSpec.describe ForecastXmlPresenter do
  let(:forecast) { Forecast.unscoped.new }

  describe "#period_start_date" do
    it "returns a date formatted for IATI XML" do
      forecast.period_start_date = "25 June 2020"
      expect(described_class.new(forecast).period_start_date).to eq("2020-06-25")
    end
  end

  describe "#period_end_date" do
    it "returns a human readable date" do
      forecast.period_end_date = "October 20, 2020"
      expect(described_class.new(forecast).period_end_date).to eq("2020-10-20")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places formatted for IATI XML" do
      forecast.value = 100_000
      expect(described_class.new(forecast).value).to eq("100000.00")
    end
  end

  describe "#forecast_type" do
    it "returns the numeric value for the forecast type" do
      forecast.forecast_type = :original
      expect(described_class.new(forecast).forecast_type).to eq "1"
    end
  end
end
