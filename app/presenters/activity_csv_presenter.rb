class ActivityCsvPresenter < ActivityPresenter
  def intended_beneficiaries
    return if super.blank?
    to_model.intended_beneficiaries.map { |item| I18n.t("activity.recipient_country.#{item}") }.join("; ")
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
end
