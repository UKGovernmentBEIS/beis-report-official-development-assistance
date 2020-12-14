require "date"

class ImportTransactions
  Error = Struct.new(:row, :column, :value, :message) {
    def csv_row
      row + 2
    end
  }

  attr_reader :errors

  def self.column_headings
    Converter::FIELDS.values
  end

  def initialize(report:, uploader:)
    @report = report
    @uploader = uploader
    @errors = []
  end

  def import(transactions)
    ActiveRecord::Base.transaction do
      transactions.each_with_index { |row, index| import_row(row, index) }
      raise ActiveRecord::Rollback unless @errors.empty?
    end
  end

  def import_row(row, index)
    importer = RowImporter.new(@report, @uploader, row)
    importer.import_row

    importer.errors.each do |attr_name, (value, message)|
      add_error(index, attr_name, value, message)
    end
  end

  def add_error(row_number, column, value, message)
    @errors << Error.new(row_number, Converter::FIELDS[column], value, message)
  end

  class RowImporter
    TRANSACTION_TYPE_DISBURSEMENT = "3"

    attr_reader :errors

    def initialize(report, uploader, row)
      @report = report
      @uploader = uploader
      @row = row
      @errors = {}
    end

    def import_row
      @converter = Converter.new(@row)
      @errors.update(@converter.errors)

      authorise_activity
      create_transaction
    end

    private

    def authorise_activity
      activity_id = @converter.raw(:activity)
      @activity = @converter.activity
      policy = ActivityPolicy.new(@uploader, @activity)

      if @activity.nil?
        @errors[:activity] = [activity_id, I18n.t("importer.errors.transaction.unknown_identifier")]
      elsif @activity && !policy.create?
        @errors[:activity] = [activity_id, I18n.t("importer.errors.transaction.unauthorised")]
      elsif !reportable_activity?
        @errors[:activity] = [activity_id, I18n.t("importer.errors.transaction.unauthorised")]
      end
    end

    def reportable_activity?
      @activity.organisation == @report.organisation && @activity.associated_fund == @report.fund
    end

    def create_transaction
      return unless @activity && @errors.empty?

      attrs = @converter.to_h
      assign_default_values(attrs)

      creator = CreateTransaction.new(activity: @activity, report: @report)
      result = creator.call(attributes: attrs)
      return unless result

      result.object.errors.each do |attr_name, message|
        @errors[attr_name] ||= [@converter.raw(attr_name), message]
      end
    end

    def assign_default_values(attrs)
      organisation = @activity.providing_organisation

      attrs[:currency] = organisation.default_currency
      attrs[:transaction_type] = TRANSACTION_TYPE_DISBURSEMENT
      attrs[:providing_organisation_reference] = organisation.iati_reference
      attrs[:providing_organisation_name] = organisation.name
      attrs[:providing_organisation_type] = organisation.organisation_type

      presenter = ReportPresenter.new(@report)
      attrs[:description] = "#{presenter.financial_quarter_and_year} spend on #{@activity.description}"
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
    rescue Encoding::CompatibilityError
      @errors[attr_name] = [
        original_value.force_encoding("UTF-8"),
        I18n.t("importer.errors.transaction.invalid_characters"),
      ]
      nil
    rescue => error
      @errors[attr_name] = [original_value, error.message]
      nil
    end

    def convert_activity(id)
      Activity.by_roda_identifier(id)
    end

    def convert_date(date)
      return nil unless date.present?
      Date.iso8601(date)
    rescue ArgumentError
      raise I18n.t("importer.errors.transaction.invalid_date")
    end

    def convert_value(value)
      ConvertFinancialValue.new.convert(value)
    rescue ConvertFinancialValue::Error
      raise I18n.t("importer.errors.transaction.non_numeric_value")
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
