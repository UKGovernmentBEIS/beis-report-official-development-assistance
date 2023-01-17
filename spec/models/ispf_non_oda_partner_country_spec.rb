require "spec_helper"

RSpec.describe IspfNonOdaPartnerCountry do
  describe "IspfNonOdaPartnerCountry" do
    it "inherits from IspfPartnerCountry" do
      expect(IspfNonOdaPartnerCountry).to be < IspfPartnerCountry
    end
  end
end
