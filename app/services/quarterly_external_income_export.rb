class QuarterlyExternalIncomeExport
  HEADERS = [
    "RODA identifier",
    "Delivery partner identifier",
    "Delivery partner organisation",
    "Title",
    "Level",
    "Providing organisation",
    "ODA",
  ]

  def initialize(organisation:, source_fund:)
    @organisation = organisation
    @source_fund = source_fund
  end

  def headers
    return HEADERS if external_incomes.empty?

    HEADERS + financial_quarter_range.map(&:to_s)
  end

  def rows
    external_incomes.map do |record|
      activity_data(record.activity) + external_income_data(record) + fq_data(record)
    end
  end

  def filename
    "#{@source_fund.short_name}_#{@organisation.beis_organisation_reference}_external_income.csv"
  end

  private

  def activity_data(activity)
    [
      activity.roda_identifier,
      activity.delivery_partner_identifier,
      @organisation.name,
      activity.title,
      I18n.t("table.body.activity.level.#{activity.level}"),
    ]
  end

  def external_income_data(external_income)
    [
      external_income.organisation.name,
      I18n.t("table.body.external_income.oda_funding.#{external_income.oda_funding?}"),
    ]
  end

  def fq_data(external_income)
    return [] if external_incomes.empty?

    financial_quarter_range.map do |quarter|
      value = if external_income.own_financial_quarter == quarter
        external_income.amount
      else
        0
      end
      "%.2f" % value
    end
  end

  def external_incomes
    @_external_incomes ||= ExternalIncome.includes(:activity, :organisation).where(activity_id: activity_ids).order(:activity_id, :financial_year, :financial_quarter)
  end

  def activity_ids
    Activity.where(organisation_id: @organisation.id, source_fund_code: @source_fund.id).pluck(:id)
  end

  def financial_quarters
    external_incomes.map(&:own_financial_quarter).uniq
  end

  def financial_quarter_range
    @_financial_quarter_range ||= Range.new(*financial_quarters.minmax)
  end
end
