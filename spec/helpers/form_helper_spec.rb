require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_organisations" do
    it "asks for a sorted list of organisations" do
      expect(Organisation).to receive(:sorted_by_name)
      helper.list_of_organisations
    end
  end

  describe "#list_of_delivery_partners" do
    it "asks for a list of organisations that are not `service_owner`" do
      delivery_partner = build_stubbed(:delivery_partner_organisation)
      allow(Organisation).to receive(:delivery_partners).and_return([delivery_partner])

      expect(Organisation).to receive(:delivery_partners)
      helper.list_of_delivery_partners
    end
  end
end
