class DateWithinBoundariesValidator < ActiveModel::EachValidator
  MIN = 17
  MAX = 25

  def validate_each(record, attribute, value)
    return unless value

    unless value.between?(MIN.years.ago, MAX.years.from_now)
      record.errors.add(
        attribute,
        I18n.t("activerecord.errors.models.#{record.class.name.underscore.downcase}.attributes.#{attribute}.between", min: MIN, max: MAX)
      )
    end
  end
end
