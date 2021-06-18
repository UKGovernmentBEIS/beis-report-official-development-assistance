class RodaIdentifierValidator < ActiveModel::Validator
  VALILD_IDENTIFIER = /^[A-Za-z0-9\-\_\/\\]+$/

  def validate(activity)
    fragment = activity.roda_identifier_fragment
    return if fragment.blank?

    unless VALILD_IDENTIFIER.match?(fragment)
      activity.errors.add(:roda_identifier_fragment,
        I18n.t("activerecord.errors.models.activity.attributes.roda_identifier_fragment.invalid_characters"))
    end

    validate_for_fund(activity, fragment) if activity.fund?
    validate_for_programme(activity, fragment) if activity.programme?
    validate_for_project(activity, fragment) if activity.project?
    validate_for_third_party_project(activity, fragment) if activity.third_party_project?
  end

  private

  def validate_for_fund(activity, fragment)
    limit = 5
    check_size(activity, fragment, limit, :level_a_too_long)
  end

  def validate_for_programme(activity, fragment)
    parent_fragment = activity.parent.roda_identifier_fragment
    limit = 18 - parent_fragment.size - 1

    check_size(activity, fragment, limit, :level_b_too_long)
  end

  def validate_for_project(activity, fragment)
    limit = 20
    check_size(activity, fragment, limit, :level_c_too_long)
  end

  def validate_for_third_party_project(activity, fragment)
    parent_fragment = activity.parent.roda_identifier_fragment
    limit = 21 - parent_fragment.size

    check_size(activity, fragment, limit, :level_d_too_long)
  end

  def check_size(activity, fragment, limit, error_type)
    if fragment.size > limit
      activity.errors.add(:roda_identifier_fragment, error_type, limit: limit)
    end
  end
end
