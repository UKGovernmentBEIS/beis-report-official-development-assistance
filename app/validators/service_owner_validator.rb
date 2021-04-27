class ServiceOwnerValidator < ActiveModel::Validator
  def validate(activity)
    unless activity.organisation.service_owner?
      activity.errors.add(:organisation,
        I18n.t("activerecord.errors.models.activity.attributes.organisation_id.invalid"))
    end
  end
end
