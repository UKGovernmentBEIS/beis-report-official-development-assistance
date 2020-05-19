class EndDateNotBeforeStartDateValidator < ActiveModel::Validator
  def validate(record)
    unless start_date_not_after_end_date?(record.period_start_date, record.period_end_date)
      record.errors.add :period_end_date, I18n.t("activerecord.errors.validators.end_date_not_before_start_date")
    end
  end

  private

  def start_date_not_after_end_date?(start_date, end_date)
    start_date <= end_date
  end
end
