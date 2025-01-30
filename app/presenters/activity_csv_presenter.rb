class ActivityCsvPresenter < ActivityPresenter
  include CountryHelper
  include CodelistHelper

  def benefitting_countries
    return if super.blank?
    list_of_countries(to_model.benefitting_countries, BenefittingCountry)
  end

  def intended_beneficiaries
    return if super.blank?
    list_of_countries(to_model.intended_beneficiaries, BenefittingCountry)
  end

  def ispf_oda_partner_countries
    return if super.blank?
    list_of_countries(to_model.ispf_oda_partner_countries, IspfOdaPartnerCountry)
  end

  def ispf_non_oda_partner_countries
    return if super.blank?
    list_of_countries(to_model.ispf_non_oda_partner_countries, IspfNonOdaPartnerCountry)
  end

  def beis_identifier
    super.to_s
  end

  def is_oda
    (super) ? "ODA" : "Non-ODA"
  end

  def linked_activity_identifier
    return unless is_ispf_funded?
    return if linked_activity.blank?
    linked_activity.roda_identifier
  end

  def country_partner_organisations
    return if super.blank?
    super.join("|")
  end

  def ispf_themes
    return if super.blank?
    ispf_themes_options.select { |theme| theme.code.in?(to_model.ispf_themes) }
      .map(&:description)
      .join("|")
  end

  def implementing_organisations
    return if super.empty?
    super.pluck(:name).join("|")
  end

  def fstc_applies
    return if super.nil? && is_non_oda?

    (super) ? "yes" : "no"
  end

  # We want the sectors, aid type and flow to be displayed with their codes
  # so we replicate X_with_code without creating an infinite loop
  def sector
    return if super.blank?
    "#{to_model.sector}: #{super}"
  end

  def aid_type
    return if super.blank?
    "#{to_model.aid_type}: #{super}"
  end

  def flow
    return nil if to_model.flow.nil?

    "#{to_model.flow}: #{super}"
  end

  def finance
    return nil if to_model.finance.nil?

    "#{to_model.finance}: #{super}"
  end

  def tied_status
    return nil if to_model.tied_status.nil?

    "#{to_model.tied_status}: #{super}"
  end

  def parent_programme_identifier
    return parent.roda_identifier if to_model.level == "project"
    parent.parent.roda_identifier if to_model.level == "third_party_project"
  end

  def parent_programme_title
    return parent.title if to_model.level == "project"
    parent.parent.title if to_model.level == "third_party_project"
  end

  def parent_project_identifier
    parent.roda_identifier if to_model.level == "third_party_project"
  end

  def parent_project_title
    parent.title if to_model.level == "third_party_project"
  end

  def publish_to_iati
    return if super.nil?

    translate("boolean.#{super}")
  end

  def sustainable_development_goals
    if sdgs_apply == false && step_is_complete_or_next?(activity: self, step: :sustainable_development_goals)
      "Not applicable"
    else
      goals = [sdg_1, sdg_2, sdg_3].compact
      return if goals.blank?

      goals.map { |goal| translate("form.label.activity.sdg_options.#{goal}") }.join("; ")
    end
  end

  def tags
    return if self[:tags].blank?

    tags_options.select { |tag| tag.code.in?(self[:tags]) }
      .map(&:description)
      .join("|")
  end

  private

  def list_of_countries(country_code_list, klass)
    country_names = country_names_from_code_list(country_code_list, klass)
    return unless country_names.present?

    country_names.join("; ")
  end
end
