class ActivityCsvPresenter < ActivityPresenter
  def benefitting_countries
    return if super.blank?
    list_of_benefitting_countries(to_model.benefitting_countries)
  end

  def intended_beneficiaries
    return if super.blank?
    list_of_benefitting_countries(to_model.intended_beneficiaries)
  end

  def beis_identifier
    super.to_s
  end

  def country_delivery_partners
    return if super.blank?
    super.join("|")
  end

  def implementing_organisations
    return if super.empty?
    super.pluck(:name).join("|")
  end

  def fstc_applies
    super ? "yes" : "no"
  end

  # We want the sectors to be displayed with their codes
  def sector
    return if super.blank?
    "#{to_model.sector}: #{super}"
  end

  private

  def list_of_benefitting_countries(country_code_list)
    return nil unless country_code_list.present?
    benefitting_country_names = country_code_list.map { |country_code|
      benefitting_country = BenefittingCountry.find_by_code(country_code)
      benefitting_country.nil? ? translate("page_content.activity.unknown_country") : benefitting_country.name
    }
    benefitting_country_names.join("; ")
  end
end
