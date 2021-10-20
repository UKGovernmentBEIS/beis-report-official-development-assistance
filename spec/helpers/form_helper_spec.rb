require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_organisations" do
    it "asks for a sorted list of organisations" do
      expect(Organisation).to receive(:sorted_by_name)
      helper.list_of_organisations
    end
  end

  describe "#list_of_delivery_partners" do
    it "asks for a list of organisations that are delivery partners" do
      _beis = create(:beis_organisation)
      delivery_partner_1 = create(:delivery_partner_organisation, name: "aaaaa")
      delivery_partner_2 = create(:delivery_partner_organisation, name: "zzzzz")

      _matched_effort_provider = create(:matched_effort_provider)
      _external_income_provider = create(:external_income_provider)

      expect(helper.list_of_delivery_partners).to match_array([
        delivery_partner_1,
        delivery_partner_2,
      ])
    end
  end

  describe "#list_of_reporting_organisations" do
    it "asks for a list of organisations that are delivery partners or the `service_owner`" do
      beis = create(:beis_organisation)
      delivery_partner_1 = create(:delivery_partner_organisation, name: "aaaaa")
      delivery_partner_2 = create(:delivery_partner_organisation, name: "zzzzz")

      _matched_effort_provider = create(:matched_effort_provider)
      _external_income_provider = create(:external_income_provider)

      expect(helper.list_of_reporting_organisations).to match_array([
        delivery_partner_1,
        beis,
        delivery_partner_2,
      ])
    end
  end

  describe "#list_of_budget_financial_years" do
    it "returns the values in the correct format" do
      expect(helper.list_of_budget_financial_years.first.id).to eq 2010
      expect(helper.list_of_budget_financial_years.first.name).to eq "2010-2011"
    end
  end
end
