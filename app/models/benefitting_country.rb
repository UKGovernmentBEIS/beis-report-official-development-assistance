class BenefittingCountry
  include ActiveModel::Model
  attr_accessor :name, :recipient_code, :code, :regions

  class << self
    def all
      @all ||= Codelist.new(type: "benefitting_countries", source: "beis").map { |country| new_from_hash(country) }
    end

    def find_by_code(code)
      all.find { |country| country.code == code }
    end

    def region_from_country_codes(codes)
      codes.map { |c| find_by_code(c) }
        .map { |c| c.regions }
        .inject(:&).last || Region::DEVELOPING_COUNTRIES_REGION
    end

    private

    def new_from_hash(country)
      new(
        name: country["name"],
        code: country["code"],
        recipient_code: country["recipient_code"],
        regions: country["regions"].map { |region|
          Region.new(
            name: region["name"],
            code: region["code"],
            level: region["level"],
          )
        }
      )
    end
  end

  class Region
    include ActiveModel::Model
    attr_accessor :name, :code, :level

    DEVELOPING_COUNTRIES_REGION = new(
      name: "Developing countries, unspecified",
      code: "998",
      level: 1,
    )

    def hash
      code.hash
    end

    def eql?(other)
      code == other.code
    end
  end
end
