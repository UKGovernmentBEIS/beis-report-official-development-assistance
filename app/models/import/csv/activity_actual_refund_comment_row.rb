class Import::Csv::ActivityActualRefundCommentRow
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
    comment = @row.field("Comment")
    return nil if comment.blank?

    comment
  end

  def roda_identifier
    @row.field("Activity RODA Identifier")
  end

  def financial_quarter
    @row.field("Financial Quarter")
  end

  def financial_year
    @row.field("Financial Year")
  end

  def receiving_organisation_name
    @row.field("Receiving Organisation Name")
  end

  def receiving_organisation_type
    @row.field("Receiving Organisation Type")
  end

  def receiving_organisation_iati_reference
    @row.field("Receiving Organisation IATI Reference")
  end

  private def original_actual_value
    @actual.original_value
  end

  private def original_refund_value
    @refund.original_value
  end

  private def validate_roda_identifier
    if roda_identifier.blank?
      @errors["Activity RODA Identifier"] = [roda_identifier, "Is required"]
      return false
    end

    true
  end

  private def validate_financial_quarter
    if financial_quarter.blank?
      @errors["Financial Quarter"] = [financial_quarter, "Is required"]
      return false
    end

    if ["1", "2", "3", "4"].none?(financial_quarter)
      @errors["Financial Quarter"] = [financial_quarter, "Must be 1, 2, 3 or 4"]
      return false
    end

    true
  end

  private def validate_financial_year
    if financial_year.blank?
      @errors["Financial Year"] = [financial_year, "Is required"]
      return false
    end

    begin
      FinancialYear.new(financial_year)
    rescue ::FinancialYear::InvalidYear
      @errors["Financial Year"] = [financial_year, "Must be a four digit year"]
      return false
    end

    true
  end

  private def validate_actual
    if actual_value.nil?
      @errors["Actual Value"] = [original_actual_value, "Must be a financial value"]
      return false
    end
    true
  end

  private def validate_refund
    if refund_value.nil?
      @errors["Refund Value"] = [original_refund_value, "Must be a financial value"]
      return false
    end
    true
  end

  private def validate_no_actual_and_refund
    if actual_value.positive? && (refund_value.positive? || refund_value.negative?)
      @errors["Actual Value"] = [actual_value, "Actual and refund cannot be reported on the same row"]
      @errors["Refund Value"] = [actual_value, "Refund and actual cannot be reported on the same row"]
      return false
    end
    true
  end

  private def validate_refund_must_have_comment
    if actual_value.zero? && !refund_value.zero? && comment.nil?
      @errors["Comment"] = ["Empty", "Refund must have a comment"]
      return false
    end
    true
  end

  private def validate_receiving_organisation_type
    return true if receiving_organisation_type.blank?

    unless value_in_code_list?("organisation_type", receiving_organisation_type)
      @errors["Receiving Organisation Type"] = [
        receiving_organisation_type, I18n.t("importer.errors.actual.invalid_iati_organisation_type")
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
