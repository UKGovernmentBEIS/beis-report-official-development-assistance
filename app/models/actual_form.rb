class ActualForm
  include ActiveModel::Model

  attr_accessor :financial_quarter, :financial_year, :report,
    :value, :parent_activity, :id, :comment,
    :receiving_organisation_name, :receiving_organisation_type, :receiving_organisation_reference

  validates :financial_quarter, presence: true
  validates :financial_year, presence: true
  validates :value, presence: true
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :value,
    numericality: {greater_than: 0},
    unless: proc { |actual| actual.validation_context == :history }

  validates_with TransactionOrganisationValidator

  def initialize(params = {})
    @financial_quarter = params[:financial_quarter]
    @financial_year = params[:financial_year]
    @value = convert_value(params[:value])
    @receiving_organisation_name = params[:receiving_organisation_name]
    @receiving_organisation_type = params[:receiving_organisation_type]
    @receiving_organisation_reference = params[:receiving_organisation_reference]
    @parent_activity = params[:parent_activity]
    @report = params[:report]
    @id = params[:id]
    @comment = params[:comment]
    @persisted = params[:persisted]
  end

  def attributes
    {
      financial_quarter: financial_quarter,
      financial_year: financial_year,
      value: value,
      receiving_organisation_name: receiving_organisation_name,
      receiving_organisation_type: receiving_organisation_type,
      receiving_organisation_reference: receiving_organisation_reference,
      comment: comment
    }
  end

  def persisted?
    @persisted.present?
  end

  private

  def convert_value(value)
    return nil if value.blank?

    ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    errors.add(:value, I18n.t("activerecord.errors.models.actual.attributes.value.not_a_number"))
    value
  end
end
