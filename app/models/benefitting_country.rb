class BenefittingCountry
  include ActiveModel::Model
  attr_accessor :name, :recipient_code, :code, :graduated, :regions

  class << self
    def all
      @all ||= Codelist.new(type: "benefitting_countries", source: "beis").map { |country| new_from_hash(country) }
    end

    def non_graduated
      @non_graduated ||= all.select { |country| !country.graduated }
    end

    def find_by_code(code)
      all.find { |country| country.code == code }
    end

    def find_non_graduated_country_by_code(code)
      non_graduated.find { |country| country.code == code }
    end

    def non_graduated_for_region(region)
      non_graduated.select { |country| country.regions.include?(region) }
    end

    def region_from_country_codes(codes)
      codes.filter_map { |code| find_by_code(code) if find_by_code(code).present? }
        .map { |c| c.regions }
        .inject(:&)
        .max_by { |r| r.level.code } || BenefittingRegion.find_by_code(BenefittingRegion::DEVELOPING_COUNTRIES_CODE)
    end

    private

    def new_from_hash(country)
      new(
        name: country["name"],
        code: country["code"],
        recipient_code: country["recipient_code"],
        graduated: country["graduated"],
        regions: country["regions"].map { |region|
          BenefittingRegion.find_by_code(region)
        }
      )
    end
  end
end
