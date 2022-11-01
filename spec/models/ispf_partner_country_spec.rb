require "spec_helper"

RSpec.describe PartnerCountry do
  let(:countries) do
    [
      PartnerCountry.new(
        code: "BR",
        name: "Brazil",
        oda: true,
        non_oda: false
      ),
      PartnerCountry.new(
        code: "CA",
        name: "Canada",
        oda: false,
        non_oda: true
      ),
      PartnerCountry.new(
        code: "CN",
        name: "China",
        oda: false,
        non_oda: true
      ),
      PartnerCountry.new(
        code: "EG",
        name: "Egypt",
        oda: true,
        non_oda: false
      ),
      PartnerCountry.new(
        code: "IN",
        name: "India",
        oda: true,
        non_oda: true
      )
    ]
  end

  before do
    allow(PartnerCountry).to receive(:all).and_return(countries)
  end

  describe ".all" do
    it "includes all countries" do
      expect(PartnerCountry.all).to match countries
    end
  end

  describe ".find_by_code" do
    context "when a country exists with the given code" do
      let(:code) { "BR" }

      it "returns a hash with the country's details" do
        partner_country = PartnerCountry.find_by_code(code)

        expect(partner_country.code).to eq("BR")
        expect(partner_country.name).to eq("Brazil")
        expect(partner_country.oda).to eq(true)
        expect(partner_country.non_oda).to eq(false)
      end
    end

    context "when a country does not exist with the given code" do
      let(:code) { "ZZ" }

      it "returns nil" do
        expect(PartnerCountry.find_by_code(code)).to be_nil
      end
    end
  end
end
