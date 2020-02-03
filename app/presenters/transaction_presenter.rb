class TransactionPresenter < SimpleDelegator
  def transaction_type
    return if super.blank?
    I18n.t("transaction.transaction_type.#{super}")
  end

  def date
    return if super.blank?
    I18n.l(super)
  end

  def currency
    return if super.blank?
    I18n.t("generic.default_currency.#{super.downcase}")
  end

  def disbursement_channel
    return if super.blank?
    I18n.t("transaction.disbursement_channel.#{super}")
  end
end
