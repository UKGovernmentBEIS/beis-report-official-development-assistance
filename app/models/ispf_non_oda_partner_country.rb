class IspfNonOdaPartnerCountry < IspfPartnerCountry
  class << self
    private

    def codelist_type
      "ispf_non_oda_partner_countries"
    end
  end
end
