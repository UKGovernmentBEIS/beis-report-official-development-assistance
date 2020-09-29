class ActivityCsvPresenter < ActivityPresenter
  def intended_beneficiaries
    return if super.blank?
    to_model.intended_beneficiaries.map { |item| I18n.t("activity.recipient_country.#{item}") }.join("; ")
  end
end
