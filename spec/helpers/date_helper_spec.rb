require "rails_helper"

RSpec.describe DateHelper, type: :helper do
  describe "#format_date" do
    it "returns a Date object from params" do
      params = {day: "1", month: "2", year: "2020"}
      expect(helper.format_date(params)).to eq(Date.new(2020, 2, 1))
    end

    it "returns nil when passed nil" do
      params = {}
      expect(helper.format_date(params)).to eq(nil)
    end

    it "returns nil when the date params are incomplete" do
      params = {day: "", month: "", year: "2019"}
      expect(helper.format_date(params)).to eq(nil)
    end

    it "returns nil when given an invalid date" do
      params = {day: "40", month: "13", year: "2020"}
      expect(helper.format_date(params)).to eq(nil)
    end

    it "returns nil when given a zero parameter" do
      params = {day: "40", month: "0", year: "2020"}
      expect(helper.format_date(params)).to eq(nil)
    end
  end

  describe "#validated_date" do
    it "returns a Date object from params" do
      params = {day: "1", month: "2", year: "2020"}
      expect(helper.validated_date(params)).to eq(Date.new(2020, 2, 1))
    end

    it "returns nil when passed nil" do
      params = {}
      expect(helper.validated_date(params)).to eq(nil)
    end

    it "raises an error when the date params are incomplete" do
      params = {day: "", month: "", year: "2019"}
      expect { helper.validated_date(params) }.to raise_error(DateHelper::InvalidDateError)
    end

    it "raises an error when there are some nil date params" do
      params = {day: nil, month: "10", year: "2019"}
      expect { helper.validated_date(params) }.to raise_error(DateHelper::InvalidDateError)
    end

    it "raises an error when given an invalid date" do
      params = {day: "40", month: "13", year: "2020"}
      expect { helper.validated_date(params) }.to raise_error(DateHelper::InvalidDateError)
    end

    it "raises an error when given a zero parameter" do
      params = {day: "10", month: "0", year: "2020"}
      expect { helper.validated_date(params) }.to raise_error(DateHelper::InvalidDateError)
    end
  end
end
