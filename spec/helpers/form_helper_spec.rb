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
      delivery_partner = build_stubbed(:organisation, service_owner: false)
      allow(Organisation).to receive(:delivery_partners).and_return([delivery_partner])

      expect(Organisation).to receive(:delivery_partners)
      helper.list_of_delivery_partners
    end
  end

  describe "#list_of_planned_disbursement_budget_types" do
    it "builds a list of budget types for a planned disbursement" do
      budget_types = helper.list_of_planned_disbursement_budget_types

      expect(budget_types[0].name).to eq I18n.t("activerecord.attributes.planned_disbursement.planned_disbursement_type.original.name")
      expect(budget_types[0].description).to eq I18n.t("activerecord.attributes.planned_disbursement.planned_disbursement_type.original.description")
    end
  end
end
