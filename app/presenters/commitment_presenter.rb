class CommitmentPresenter < SimpleDelegator
  def value
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end

  def transaction_date
    return "" unless super
    I18n.l(super)
  end
end
