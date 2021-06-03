class ExternalIncomePresenter < SimpleDelegator
  def amount
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end

  def oda_funding
    super ? "Yes" : "No"
  end
end
