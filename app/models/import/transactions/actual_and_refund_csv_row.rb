class Import::Transactions::ActualAndRefundCsvRow
  attr_reader :errors

  def initialize(csv_row)
    @row = csv_row
    @errors = {}
  end

  def valid?
    validate_roda_identifier_cannot_be_blank
    validate_financial_quarter
    validate_financial_year
    validate_receiving_organisation_type

    if validate_financial_value_for("Actual Value") && validate_financial_value_for("Refund Value")
      validate_actual_and_refund_separate
      validate_activity_comment
      validate_refund_require_comment
    end

    @errors.empty?
  end

  def invalid?
    !valid?
  end

  def description
    return nil unless validate_financial_quarter && validate_financial_year

    quarter = financial_quarter
    year = financial_year

    "#{FinancialQuarter.new(quarter, year)} spend on #{activity.title}"
  end

  def activity
    @_activity ||= Activity.find_by_roda_identifier(roda_identifier)
    if @_activity.nil?
      @errors["Activity RODA Identifier"] = [roda_identifier, "Activity cannot be found"]
    end
    @_activity
  end

  def roda_identifier
    @row.field("Activity RODA Identifier") || :blank
  end

  def actual_value
    fetch_financial_value_for_column("Actual Value")
  end

  def refund_value
    fetch_financial_value_for_column("Refund Value")
  end

  def comment
    @row.field("Comment") || :blank
  end

  def providing_organisation
    return nil if activity.nil?

    activity.providing_organisation
  end

  def financial_quarter
    @row.field("Financial Quarter") || :blank
  end

  def financial_year
    @row.field("Financial Year") || :blank
  end

  def receiving_organisation_name
    @row.field("Receiving Organisation Name") || :blank
  end

  def receiving_organisation_type
    @row.field("Receiving Organisation Type") || :blank
  end

  def receiving_organisation_iati_reference
    @row.field("Receiving Organisation IATI Reference") || :blank
  end

  def transaction_type
    return nil unless validate_financial_value_for("Actual Value") && validate_financial_value_for("Refund Value")

    return :blank if blank?(actual_value) && blank?(refund_value) && blank?(comment)
    return :comment if not_blank?(comment) && exactly_zero?(actual_value) && exactly_zero?(refund_value)
    return :actual if not_blank_or_zero?(actual_value) && blank_or_zero?(refund_value)
    return :refund if not_blank_or_zero?(refund_value) && blank_or_zero?(actual_value)
  end

  private def validate_receiving_organisation_type
    return true if receiving_organisation_type.eql?(:blank)

    unless value_in_code_list?("organisation_type", receiving_organisation_type)
      @errors["Receiving Organisation Type"] = [
        receiving_organisation_type, I18n.t("importer.errors.actual.invalid_iati_organisation_type")
      ]
      return false
    end
    true
  end

  private def validate_activity_comment
    if blank?(comment) && exactly_zero?(actual_value) && exactly_zero?(refund_value)
      @errors["Comment"] = [comment, "Activities with 0 actual and 0 refund require a comment"]
    end

    if not_blank?(comment) && blank?(actual_value) && blank?(refund_value)
      @errors["Comment"] = [comment, "Actual and refund must both be zero to provide a comment"]
    end
  end

  private def validate_actual_and_refund_separate
    if not_blank_or_zero?(actual_value) && not_blank_or_zero?(refund_value)
      @errors["Actual Value"] = [actual_value, "You cannot report actual and refunds together"]
      @errors["Refund Value"] = [refund_value, "You cannot report actual and refunds together"]
    end
  end

  private def validate_financial_quarter
    if blank?(financial_quarter)
      @errors["Financial Quarter"] = [financial_quarter, "Cannot be blank"]
      return false
    elsif ["1", "2", "3", "4"].none?(financial_quarter)
      @errors["Financial Quarter"] = [financial_quarter, "Must be 1, 2, 3 or 4"]
      return false
    end
    true
  end

  private def validate_financial_year
    if blank?(financial_year)
      @errors["Financial Year"] = [financial_year, "Cannot be blank"]
      return false
    elsif financial_year.length > 4
      @errors["Financial Year"] = [financial_year, "Must be a four digit year"]
      return false
    end
    true
  end

  private def validate_roda_identifier_cannot_be_blank
    if blank?(roda_identifier)
      @errors["Activity RODA Identifier"] = [roda_identifier, "Cannot be blank"]
    end
  end

  private def validate_refund_require_comment
    if not_blank_or_zero?(refund_value) && blank_or_zero?(actual_value) && blank?(comment)
      @errors["Comment"] = [comment, "Comment is required when reporting refunds"]
    end
  end

  private def value_in_code_list?(code_list, value)
    code_list = Codelist.new(type: code_list)
    code_list.find_item_by_code(value) ? true : false
  end

  private def fetch_financial_value_for_column(header)
    value = @row.field(header)

    return :blank if value.nil?
    begin
      converted_value = ConvertFinancialValue.new.convert(value)
    rescue ConvertFinancialValue::Error
      return value
    end
    converted_value
  end

  private def validate_financial_value_for(header)
    value = @row.field(header)
    valid = true
    return true if value.nil?

    begin
      ConvertFinancialValue.new.convert(value)
    rescue ConvertFinancialValue::Error
      @errors[header] = [value, I18n.t("importer.errors.actuals_and_refunds.non_numeric")]
      valid = false
    end
    valid
  end

  private def blank?(value)
    value.eql?(:blank)
  end

  private def blank_or_zero?(value)
    return true if value.eql?(:blank)
    return true if value.zero?
    false
  end

  private def not_blank?(value)
    return false if value.eql?(:blank)
    true
  end

  private def not_blank_or_zero?(value)
    return false if value.eql?(:blank)
    return false if value.zero?
    true
  end

  private def exactly_zero?(value)
    return false if blank?(value)
    return false unless value.zero?
    true
  end
end
