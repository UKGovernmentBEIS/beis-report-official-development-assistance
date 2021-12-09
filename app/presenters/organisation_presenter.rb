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
end
