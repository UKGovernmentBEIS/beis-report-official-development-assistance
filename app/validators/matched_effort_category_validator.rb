class MatchedEffortCategoryValidator < ActiveModel::Validator
  def validate(matched_effort)
    return if matched_effort.funding_type.blank? || matched_effort.category.blank?

    funding_type = MatchedEffort::FundingType.by_coded_name(matched_effort.funding_type)
    category = MatchedEffort::Category.by_coded_name(matched_effort.category)

    category_type_codes = funding_type.categories.map(&:coded_name)

    unless category_type_codes.include?(matched_effort.category)
      matched_effort.category = nil
      matched_effort.errors.add(:category,
        I18n.t(
          "activerecord.errors.models.matched_effort.attributes.category.invalid",
          category: category.name,
          funding_type: funding_type.name
        ))
    end
  end
end
