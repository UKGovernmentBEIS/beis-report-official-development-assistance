class MatchedEffortCategoryValidator < ActiveModel::Validator
  def validate(matched_effort)
    return if matched_effort.funding_type.blank? || matched_effort.category.blank?

    type_code = MatchedEffort.funding_types[matched_effort.funding_type]
    category_code = MatchedEffort.categories[matched_effort.category]

    category_data = MatchedEffort::CATEGORY_CODES.list.find { |c| c["code"] == category_code }
    funding_type_data = MatchedEffort::FUNDING_TYPE_CODES.list.find { |c| c["code"] == type_code }

    unless category_data["funding_type"] == type_code
      matched_effort.category = nil
      matched_effort.errors.add(:category,
        I18n.t(
          "activerecord.errors.models.matched_effort.attributes.category.invalid",
          category: category_data["name"],
          funding_type: funding_type_data["name"]
        ))
    end
  end
end
