class EndDateAfterStartDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    unless end_date_after_start_date(record.planned_start_date, record.planned_end_date)
      record.errors.add :planned_end_date, :not_before_start_date
    end
  end

  private def end_date_after_start_date(start_date, end_date)
    end_date >= start_date
  end
end
