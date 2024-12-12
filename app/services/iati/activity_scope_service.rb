class Iati::ActivityScopeService
  # see vendor/data/beis_organisation_references/codelists/BEIS/benefitting_regions.yml
  REGION_LEVEL_CODE = 1

  SCOPES = {
    national: 4,
    regional: 2,
    multi_national: 3
  }.freeze

  def initialize(benefitting_country_codes)
    @benefitting_country_codes = benefitting_country_codes
  end

  def call
    return false unless @benefitting_country_codes.present?

    return SCOPES[:national] if benefitting_countries.count == 1 && benefitting_regions.count == 1
    return SCOPES[:regional] if benefitting_countries.count > 1 && benefitting_regions.count == 1
    SCOPES[:multi_national] if benefitting_countries.count > 1 && benefitting_regions.count > 1
  end

  private def benefitting_countries
    return [] if @benefitting_country_codes.nil?

    @_benefitting_countries ||= @benefitting_country_codes.map do |country_code|
      BenefittingCountry.find_by_code(country_code)
    end
  end

  private def benefitting_regions
    level = BenefittingRegion::Level.find_by_code(REGION_LEVEL_CODE)

    @_benefitting_regions ||= benefitting_countries.map do |benefitting_country|
      benefitting_country.regions.select { |region| region.level == level }
    end

    @_benefitting_regions.uniq.flatten
  end
end
