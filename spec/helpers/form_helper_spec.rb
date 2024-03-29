require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_partner_organisations" do
    it "asks for a list of organisations that are partner organisations" do
      _beis = create(:beis_organisation)
      partner_organisation_1 = create(:partner_organisation, name: "aaaaa")
      partner_organisation_2 = create(:partner_organisation, name: "zzzzz")

      _matched_effort_provider = create(:matched_effort_provider)
      _external_income_provider = create(:external_income_provider)

      expect(helper.list_of_partner_organisations).to match_array([
        partner_organisation_1,
        partner_organisation_2
      ])
    end
  end

  describe "#list_of_reporting_organisations" do
    it "asks for a list of organisations that are partner organisations or the `service_owner`" do
      beis = create(:beis_organisation)
      partner_organisation_1 = create(:partner_organisation, name: "aaaaa")
      partner_organisation_2 = create(:partner_organisation, name: "zzzzz")

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

  describe "#all_benefitting_country_codes" do
    subject { helper.all_benefitting_country_codes }

    it "returns an array of all possible benefitting country codes" do
      expect(subject.size).to be 142
      expect(subject.first).to eq "DZ"
      expect(subject.last).to eq "WS"
    end
  end
end
