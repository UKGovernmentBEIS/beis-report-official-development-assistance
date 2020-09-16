require "date"

class ImportTransactions
  Error = Struct.new(:row, :column, :value, :message)

  DEFAULT_CURRENCY = "GBP"
  TRANSACTION_TYPE_DISBURSEMENT = "3"

  attr_reader :errors

  def initialize(report:)
    @report = report
    @errors = []
  end

  def import(transactions)
    transactions.each_with_index { |row, index| import_row(row, index) }
  end

  def import_row(row, row_number)
    errors = {}

    converter = Converter.new(row)
    errors.update(converter.errors)

    activity = converter.activity
    unless activity
      errors[:activity] = [converter.raw(:activity), I18n.t("importer.errors.transaction.unknown_identifier")]
    end

    create_transaction(converter, errors)

    errors.each do |attr_name, (value, message)|
      add_error(row_number, attr_name, value, message)
    end
  end

  def add_error(row_number, column, value, message)
    @errors << Error.new(row_number, Converter::FIELDS[column], value, message)
  end

  def create_transaction(converter, errors)
    activity = converter.activity
    return unless activity

    attrs = converter.to_h
    assign_default_values(attrs, activity)

    creator = CreateTransaction.new(activity: activity, report: @report)
    result = creator.call(attributes: attrs)
    return unless result

    result.object.errors.each do |attr_name, message|
      errors[attr_name] ||= [converter.raw(attr_name), message]
    end
  end

  def assign_default_values(attrs, activity)
    organisation = activity.providing_organisation

    attrs[:currency] = DEFAULT_CURRENCY
    attrs[:transaction_type] = TRANSACTION_TYPE_DISBURSEMENT
    attrs[:providing_organisation_name] = organisation.name
    attrs[:providing_organisation_type] = organisation.organisation_type

    if attrs[:description].blank?
      presenter = ReportPresenter.new(@report)
      attrs[:description] = "#{presenter.financial_quarter_and_year} spend on #{activity.description}"
    end
  end

  class Converter
    FIELDS = {
      activity: "Activity RODA Identifier",
      date: "Date",
      value: "Value",
      receiving_organisation_name: "Receiving Organisation Name",
      receiving_organisation_type: "Receiving Organisation Type",
      receiving_organisation_reference: "Receiving Organisation IATI Reference",
      disbursement_channel: "Disbursement Channel",
      description: "Description",
    }

    attr_reader :activity, :errors

    def initialize(row)
      @row = row
      @errors = {}
      @attributes = convert_to_attributes
      @activity = @attributes.delete(:activity)
    end

    def raw(attr_name)
      @row[FIELDS[attr_name]]
    end

    def to_h
      @attributes
    end

    def convert_to_attributes
      FIELDS.each_with_object({}) do |(attr_name, column_name), attrs|
        attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name])
      end
    end

    def convert_to_attribute(attr_name, value)
      original_value = value.clone
      value = value.to_s.strip

      converter = "convert_#{attr_name}"
      value = __send__(converter, value) if respond_to?(converter)

      value
    rescue => error
      @errors[attr_name] = [original_value, error.message]
      nil
    end

    def convert_activity(id)
      Activity.find_by(roda_identifier_compound: id)
    end

    def convert_date(date)
      return nil unless date.present?
      Date.iso8601(date)
    rescue ArgumentError
      raise I18n.t("importer.errors.transaction.invalid_date")
    end

    def convert_receiving_organisation_type(type)
      validate_from_codelist(
        type,
        "organisation/organisation_type.yml",
        I18n.t("importer.errors.transaction.invalid_iati_organisation_type"),
      )
    end

    def convert_disbursement_channel(channel)
      validate_from_codelist(
        channel,
        "transaction/disbursement_channel.yml",
        I18n.t("importer.errors.transaction.invalid_iati_disbursement_channel"),
      )
    end

    def validate_from_codelist(code, codelist_file, message)
      return nil if code.blank?

      codelist_path = codelist_root.join(codelist_file)
      codelist = YAML.safe_load(File.read(codelist_path))
      valid_codes = codelist.fetch("data").map { |entry| entry.fetch("code") }

      raise message unless valid_codes.include?(code)

      code
    end

    def codelist_root
      Rails.root.join("vendor", "data", "codelists", "IATI", IATI_VERSION)
    end
  end
end
