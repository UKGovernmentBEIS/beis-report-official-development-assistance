require "rails_helper"

RSpec.describe ActivityCsvPresenter do
  describe "#intended_beneficiaries" do
    context "when there are other benefiting countries" do
      it "returns the benefiting countries separated by semicolons" do
        activity = build(:activity, intended_beneficiaries: ["AR", "EC", "BR"])
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to eql("Argentina; Ecuador; Brazil")
      end
    end

    context "when there are no other benefiting countries" do
      it "returns nil" do
        activity = build(:activity, intended_beneficiaries: nil)
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to be_nil
      end
    end
  end
end
