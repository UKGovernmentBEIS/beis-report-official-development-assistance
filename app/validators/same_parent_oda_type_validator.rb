class SameParentOdaTypeValidator < ActiveModel::Validator
  def validate(activity)
    return unless activity.is_ispf_funded?
    return if activity.is_oda.nil?
    return if activity.parent.fund?

    if activity.is_oda != activity.parent.is_oda
      activity.errors.add(:oda_parent, I18n.t("activerecord.errors.models.activity.attributes.parent.invalid"))
    end
  end
end
