class LinkedActivityValidator < ActiveModel::Validator
  attr_accessor :activity, :error_translations

  def validate(activity)
    @activity = activity
    @error_translations = I18n.t("activerecord.errors.models.activity.attributes.linked_activity_id")

    return if activity.linked_activity.nil?

    return unless validate_not_fund
    return unless validate_same_level
    return unless validate_ispf
    return unless validate_oda_type
    return unless validate_link_does_not_have_other_link
    return unless validate_same_extending_organisation
    return unless validate_no_linked_child_activities
    validate_parents_are_linked
  end

  private

  def validate_not_fund
    if activity.fund?
      activity.errors.add(:linked_activity_id, error_translations[:fund])
      return false
    end

    true
  end

  def validate_same_level
    if activity.level != activity.linked_activity.level
      activity.errors.add(:linked_activity_id, error_translations[:different_level])
      return false
    end

    true
  end

  def validate_ispf
    ispf_source_fund_code = Fund.by_short_name("ISPF").id

    if activity.source_fund_code != ispf_source_fund_code || activity.linked_activity.source_fund_code != ispf_source_fund_code
      activity.errors.add(:linked_activity_id, error_translations[:incorrect_fund])
      return false
    end

    true
  end

  def validate_oda_type
    if activity.is_oda == activity.linked_activity.is_oda
      activity.errors.add(:linked_activity_id, error_translations[:same_oda_type])
      return false
    end

    true
  end

  def validate_link_does_not_have_other_link
    if activity.linked_activity.linked_activity.present? && activity.linked_activity.linked_activity != activity
      activity.errors.add(:linked_activity_id, error_translations[:proposed_linked_has_other_link])
      return false
    end

    true
  end

  def validate_same_extending_organisation
    if activity.extending_organisation != activity.linked_activity.extending_organisation
      activity.errors.add(:linked_activity_id, error_translations[:different_extending_organisation])
      return false
    end

    true
  end

  def validate_no_linked_child_activities
    attempting_to_change_linked_activity = activity.linked_activity.linked_activity != activity

    if activity.linked_child_activities.present? && attempting_to_change_linked_activity
      activity.errors.add(:linked_activity_id, error_translations[:linked_child_activities])
      false
    end

    true
  end

  def validate_parents_are_linked
    if !activity.programme? && activity.parent.linked_activity != activity.linked_activity.parent
      activity.errors.add(:linked_activity_id, error_translations[:unlinked_parents])
      false
    end

    true
  end
end
