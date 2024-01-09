class Import::Csv::ActivityActualRefundComment::Row
  attr_reader :errors

  def initialize(csv_row)
    @row = csv_row
    @errors = {}
    @actual = Import::Csv::Financial.new(@row.field("Actual Value"))
    @refund = Import::Csv::Financial.new(@row.field("Refund Value"))
  end

  def valid?
    validate_financial_quarter
    validate_financial_year
    validate_roda_identifier
    validate_receiving_organisation_name
    validate_receiving_organisation_type

    if validate_actual && validate_refund
      validate_no_actual_and_refund
      validate_refund_must_have_comment
    end

    @errors.empty?
  end

  def invalid?
    !valid?
  end

  def empty?
    return nil unless valid?

    actual_value.zero? && refund_value.zero? && comment.nil?
  end

  def actual_value
    @actual.decimal_value
  end

  def refund_value
    @refund.decimal_value
  end

  def comment
    @row.field("Comment").tap do |comment|
      return nil if comment.blank?
    end
  end

  def roda_identifier
    @row.field("Activity RODA Identifier").tap do |identifier|
      return nil if identifier.blank?
    end
  end

  def financial_quarter
    @row.field("Financial Quarter").tap do |quarter|
      return nil if quarter.blank?
    end
  end

  def financial_year
    @row.field("Financial Year").tap do |year|
      return nil if year.blank?
    end
  end

  def receiving_organisation_name
    @row.field("Receiving Organisation Name").tap do |name|
      return nil if name.blank?
    end
  end

  def receiving_organisation_type
    @row.field("Receiving Organisation Type").tap do |type|
      return nil if type.blank?
    end
  end

  def receiving_organisation_iati_reference
    @row.field("Receiving Organisation IATI Reference").tap do |reference|
      return nil if reference.blank?
    end
  end

  private def original_actual_value
    @actual.original_value
  end

  private def original_refund_value
    @refund.original_value
  end

  private def validate_roda_identifier
    if roda_identifier.blank?
      @errors["Activity RODA Identifier"] = [roda_identifier, I18n.t("import.csv.activity_actual_refund_comment.errors.default.required")]
      return false
    end

    true
  end

  private def validate_financial_quarter
    if financial_quarter.blank?
      @errors["Financial Quarter"] = [financial_quarter, I18n.t("import.csv.activity_actual_refund_comment.errors.default.required")]
      return false
    end

    if ["1", "2", "3", "4"].none?(financial_quarter)
      @errors["Financial Quarter"] = [financial_quarter, I18n.t("import.csv.activity_actual_refund_comment.errors.financial_quarter")]
      return false
    end

    true
  end

  private def validate_financial_year
    if financial_year.blank?
      @errors["Financial Year"] = [financial_year, I18n.t("import.csv.activity_actual_refund_comment.errors.default.required")]
      return false
    end

    begin
      FinancialYear.new(financial_year)
    rescue ::FinancialYear::InvalidYear
      @errors["Financial Year"] = [financial_year, I18n.t("import.csv.activity_actual_refund_comment.errors.financial_year")]
      return false
    end

    true
  end

  private def validate_actual
    if actual_value.nil?
      @errors["Actual Value"] = [original_actual_value, I18n.t("import.csv.activity_actual_refund_comment.errors.financial_value")]
      return false
    end
    true
  end

  private def validate_refund
    if refund_value.nil?
      @errors["Refund Value"] = [original_refund_value, I18n.t("import.csv.activity_actual_refund_comment.errors.financial_value")]
      return false
    end
    true
  end

  private def validate_no_actual_and_refund
    if actual_value.positive? && (refund_value.positive? || refund_value.negative?)
      @errors["Actual Value"] = [original_actual_value, I18n.t("import.csv.activity_actual_refund_comment.errors.actual_value_with_refund")]
      @errors["Refund Value"] = [original_refund_value, I18n.t("import.csv.activity_actual_refund_comment.errors.refund_value_with_actual")]
      return false
    end
    true
  end

  private def validate_refund_must_have_comment
    if actual_value.zero? && !refund_value.zero? && comment.nil?
      @errors["Comment"] = [comment, I18n.t("import.csv.activity_actual_refund_comment.errors.refund_requires_comment")]
      return false
    end
    true
  end

  private def validate_receiving_organisation_name
    if receiving_organisation_name.blank? && receiving_organisation_type.present?
      @errors["Receiving Organisation Name"] = [
        receiving_organisation_name, I18n.t("import.csv.activity_actual_refund_comment.errors.receiving_organisation_name.type")
      ]
      return false
    end

    if receiving_organisation_name.blank? && receiving_organisation_iati_reference.present?
      @errors["Receiving Organisation Name"] = [
        receiving_organisation_name, I18n.t("import.csv.activity_actual_refund_comment.errors.receiving_organisation_name.reference")
      ]
      return false
    end

    true
  end

  private def validate_receiving_organisation_type
    return true if receiving_organisation_name.blank? && receiving_organisation_type.blank?

    if receiving_organisation_name.present? && receiving_organisation_type.blank?
      @errors["Receiving Organisation Type"] = [
        receiving_organisation_type, I18n.t("import.csv.activity_actual_refund_comment.errors.receiving_organisation_type.blank_name")
      ]
      return false
    end

    unless value_in_code_list?("organisation_type", receiving_organisation_type)
      @errors["Receiving Organisation Type"] = [
        receiving_organisation_type, I18n.t("import.csv.activity_actual_refund_comment.errors.receiving_organisation_type.invalid_code")
      ]
      return false
    end

    true
  end

  private def value_in_code_list?(code_list, value)
    code_list = Codelist.new(type: code_list)
    code_list.find_item_by_code(value) ? true : false
  end
end
