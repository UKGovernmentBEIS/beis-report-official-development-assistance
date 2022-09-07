require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_organisations" do
    it "asks for a sorted list of organisations" do
      expect(Organisation).to receive(:sorted_by_name)
      helper.list_of_organisations
    end
  end

  describe "#list_of_delivery_partners" do
    it "asks for a list of organisations that are partner organisations" do
      _beis = create(:beis_organisation)
      partner_organisation_1 = create(:delivery_partner_organisation, name: "aaaaa")
      partner_organisation_2 = create(:delivery_partner_organisation, name: "zzzzz")

      _matched_effort_provider = create(:matched_effort_provider)
      _external_income_provider = create(:external_income_provider)

      expect(helper.list_of_delivery_partners).to match_array([
        partner_organisation_1,
        partner_organisation_2
      ])
    end
  end

  describe "#list_of_reporting_organisations" do
    it "asks for a list of organisations that are partner organisations or the `service_owner`" do
      beis = create(:beis_organisation)
      partner_organisation_1 = create(:delivery_partner_organisation, name: "aaaaa")
      partner_organisation_2 = create(:delivery_partner_organisation, name: "zzzzz")

      _matched_effort_provider = create(:matched_effort_provider)
      _external_income_provider = create(:external_income_provider)

      expect(helper.list_of_reporting_organisations).to match_array([
        partner_organisation_1,
        beis,
        partner_organisation_2
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
