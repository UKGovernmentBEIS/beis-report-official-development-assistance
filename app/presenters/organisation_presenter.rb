# frozen_string_literal: true

class OrganisationPresenter < SimpleDelegator
  def language_code
    return I18n.t("organisation.language_code.#{super.downcase}") if super

    super
  end

  def default_currency
    return I18n.t("generic.default_currency.#{super.downcase}") if super

    super
  end

  def organisation_type
    I18n.t("organisation.organisation_type.#{super}")
  end

  def filename_for_activities_template(type:)
    type_string = I18n.t("action.activity.type")[type]
    formatted_type = type_string.gsub(/[ \/]/, "_")

    [
      beis_organisation_reference,
      "Level_B_#{formatted_type}_activities_upload"
    ].compact.join("-") + ".csv"
  end
end
