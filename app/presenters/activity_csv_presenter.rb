class ActivityCsvPresenter < ActivityPresenter
  def intended_beneficiaries
    return if super.blank?
    to_model.intended_beneficiaries.map { |item| I18n.t("activity.recipient_country.#{item}") }.join("; ")
  end

  def beis_id
    super.to_s
  end

  def country_delivery_partners
    return if super.blank?
    super.join(" | ")
  end
end
