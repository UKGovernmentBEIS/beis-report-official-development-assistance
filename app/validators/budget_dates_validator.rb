class BudgetDatesValidator < ActiveModel::Validator
  def validate(record)
    return if record.ingested?
    unless dates_not_more_than_365_days_apart?(record.period_start_date, record.period_end_date)
      record.errors.add :period_end_date,
        I18n.t("activerecord.errors.models.budget.attributes.period_end_date.within_365_days_of_start_date")
    end

    unless start_date_not_after_end_date?(record.period_start_date, record.period_end_date)
      record.errors.add :period_start_date, I18n.t("activerecord.errors.models.budget.attributes.period_start_date.not_after_end_date")
    end
  end

  private

  def dates_not_more_than_365_days_apart?(start_date, end_date)
    end_date - 365.days <= start_date
  end

  def start_date_not_after_end_date?(start_date, end_date)
    start_date <= end_date
  end
end
