require "rails_helper"

RSpec.describe TotalPresenter do
  describe "#value" do
    it "returns a currency formatted string" do
      expect(TotalPresenter.new(BigDecimal("4321.1")).value).to eq("£4,321.10")
    end
  end
end
