# This is an abstract class, inherited by `IspfOdaPartnerCountry` and
# `IspfNonOdaPartnerCountry`. They are identical except the codelist they use.
# `codelist_type` is not implemented in this class, only in the two classes that
# inherit from it

class IspfPartnerCountry
  include ActiveModel::Model
  attr_accessor :name, :code

  class << self
    def find_by_code(code)
      all.find { |country| country.code == code }
    end

    private

    def all
      @all ||= Codelist.new(type: codelist_type, source: "beis").map { |country| new_from_hash(country) }
    end

    def new_from_hash(country)
      new(
        name: country["name"],
        code: country["code"]
      )
    end
  end
end
