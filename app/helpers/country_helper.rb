module CountryHelper
  def country_names_from_code_list(country_code_list, klass)
    return nil unless country_code_list.present?

    country_code_list.map { |country_code|
      country = klass.find_by_code(country_code)
      country.nil? ? translate("page_content.activity.unknown_country", code: country_code) : country.name
    }
  end
end
