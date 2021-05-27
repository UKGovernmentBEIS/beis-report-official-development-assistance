class MatchedEffortPresenter < SimpleDelegator
  def funding_type
    return if super.blank?

    id = MatchedEffort.funding_types[super]
    code = MatchedEffort::FUNDING_TYPE_CODES.list[id]
    code["name"]
  end

  def category
    return if super.blank?

    id = MatchedEffort.categories[super]
    code = MatchedEffort::CATEGORY_CODES.list[id]
    code["name"]
  end

  def committed_amount
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
