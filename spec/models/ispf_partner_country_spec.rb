require "spec_helper"

RSpec.describe IspfPartnerCountry do
  let(:countries) do
    [
      IspfPartnerCountry.new(
        code: "BR",
        name: "Brazil"
      ),
      IspfPartnerCountry.new(
        code: "EG",
        name: "Egypt"
      ),
      IspfPartnerCountry.new(
        code: "IN",
        name: "India (ODA)"
      )
    ]
  end

  before do
    allow(IspfPartnerCountry).to receive(:all).and_return(countries)
  end

  describe ".find_by_code" do
    context "when a country exists with the given code" do
      let(:code) { "BR" }

      it "returns an instance of IspfPartnerCountry with public code and name methods" do
        partner_country = IspfPartnerCountry.find_by_code(code)

        expect(partner_country.code).to eq("BR")
        expect(partner_country.name).to eq("Brazil")
      end
    end

    context "when a country does not exist with the given code" do
      let(:code) { "ZZ" }

      it "returns nil" do
        expect(IspfPartnerCountry.find_by_code(code)).to be_nil
      end
    end
  end
end
