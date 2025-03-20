class DateWithinBoundariesValidator < ActiveModel::EachValidator
  MAX_YEARS_AGO = 27
  MAX_YEARS_IN_FUTURE = 25

  def validate_each(record, attribute, value)
    return unless value

    unless value.between?(MAX_YEARS_AGO.years.ago, MAX_YEARS_IN_FUTURE.years.from_now)
      record.errors.add(
        attribute,
        I18n.t("activerecord.errors.models.#{record.class.name.underscore.downcase}.attributes.#{attribute}.between", min: MAX_YEARS_AGO, max: MAX_YEARS_IN_FUTURE)
      )
    end
  end
end
