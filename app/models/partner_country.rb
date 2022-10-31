class PartnerCountry
  include ActiveModel::Model
  attr_accessor :name, :code, :oda, :non_oda

  class << self
    def all
      @all ||= Codelist.new(type: "ispf_partner_countries", source: "beis").map { |country| new_from_hash(country) }
    end

    def find_by_code(code)
      all.find { |country| country.code == code }
    end

    private

    def new_from_hash(country)
      new(
        name: country["name"],
        code: country["code"],
        oda: country["oda"],
        non_oda: country["non_oda"]
      )
    end
  end
end
