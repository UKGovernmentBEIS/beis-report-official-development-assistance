class TransactionPresenter < SimpleDelegator
  def date
    return if super.blank?
    I18n.l(super)
  end

  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
