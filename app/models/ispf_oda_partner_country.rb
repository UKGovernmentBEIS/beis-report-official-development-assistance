class IspfOdaPartnerCountry < IspfPartnerCountry
  class << self
    private

    def codelist_type
      "ispf_oda_partner_countries"
    end
  end
end
