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

  describe "#beis_identifier" do
    it "returns an empty string if the BEIS ID is nil otherwise the value" do
      activity = Activity.new(beis_identifier: nil)
      result = described_class.new(activity).beis_identifier

      expect(result).to eq ""

      fake_beis_identifier = "GCRF_AHRC_NS_AH1001"
      activity.beis_identifier = fake_beis_identifier
      result = described_class.new(activity).beis_identifier

      expect(result).to eq fake_beis_identifier
    end
  end

  describe "#country_delivery_partners" do
    context "when there are more than one country delivery partners" do
      it "returns them separated by pipes" do
        activity = build(:programme_activity, country_delivery_partners: ["National Council for the State Funding Agencies (CONFAP)",
                                                                          "Chinese Academy of Sciences",
                                                                          "National Research Foundation",])
        result = described_class.new(activity).country_delivery_partners
        expect(result).to eql("National Council for the State Funding Agencies (CONFAP) | Chinese Academy of Sciences | National Research Foundation")
      end
    end

    context "when there are no country delivery partners" do
      it "returns nil" do
        activity = build(:programme_activity, country_delivery_partners: nil)
        result = described_class.new(activity).country_delivery_partners
        expect(result).to be_nil
      end
    end
  end
end
