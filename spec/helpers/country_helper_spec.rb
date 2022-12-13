require "rails_helper"

RSpec.describe CountryHelper, type: :helper do
  describe "#country_names_from_code_list" do
    context "when there are countries passed in" do
      it "returns the list of names for the codes of the countries passed in" do
        activity = build(:project_activity, benefitting_countries: ["AR", "EC", "BR"])
        result = country_names_from_code_list(activity.benefitting_countries, BenefittingCountry)
        expect(result).to eq(["Argentina", "Ecuador", "Brazil"])
      end
    end

    context "when no countries are passed in" do
      it "returns nil" do
        result = country_names_from_code_list([], BenefittingCountry)
        expect(result).to eq(nil)
      end
    end

    it "handles unexpected country codes" do
      activity = build(:project_activity, benefitting_countries: ["UK"])
      result = country_names_from_code_list(activity.benefitting_countries, BenefittingCountry)
      expect(result).to eq([t("page_content.activity.unknown_country", code: "UK")])
    end
  end
end
