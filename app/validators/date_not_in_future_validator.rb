class DateNotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    if in_future?(value)
      record.errors.add(
        attribute,
        I18n.t("activerecord.errors.models.#{record.class.name.downcase}.attributes.#{attribute}.not_in_future")
      )
    end
  end

  def in_future?(date)
    date > Time.zone.today
  end
end
