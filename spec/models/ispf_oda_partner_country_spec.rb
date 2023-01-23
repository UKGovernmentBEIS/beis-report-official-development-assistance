require "spec_helper"

RSpec.describe IspfOdaPartnerCountry do
  describe "IspfOdaPartnerCountry" do
    it "inherits from IspfPartnerCountry" do
      expect(IspfOdaPartnerCountry).to be < IspfPartnerCountry
    end
  end
end
