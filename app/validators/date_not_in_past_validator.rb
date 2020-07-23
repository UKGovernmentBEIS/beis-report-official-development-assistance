class DateNotInPastValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    if in_past?(value)
      record.errors.add(
        attribute,
        I18n.t("activerecord.errors.models.#{record.class.name.downcase}.attributes.#{attribute}.not_in_past")
      )
    end
  end

  def in_past?(date)
    Time.zone.today >= date
  end
end
