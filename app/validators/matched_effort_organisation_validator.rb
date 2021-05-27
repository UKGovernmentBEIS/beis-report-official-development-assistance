class MatchedEffortOrganisationValidator < ActiveModel::Validator
  def validate(matched_effort)
    unless matched_effort.organisation&.matched_effort_provider?
      matched_effort.errors.add(:organisation,
        I18n.t("activerecord.errors.models.matched_effort.attributes.organisation.invalid"))
    end
  end
end
