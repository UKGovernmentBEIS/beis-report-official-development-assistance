class CommitmentPresenter < SimpleDelegator
  def value
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
