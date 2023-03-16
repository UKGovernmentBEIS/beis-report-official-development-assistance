# This originally handled only Actuals, but now also handles Refunds as well.
class Actual
  class Import
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end
    }

    attr_reader :errors, :imported_actuals, :invalid_with_comment

    def self.column_headings
      Converter::FIELDS.values
    end

    def initialize(report:, uploader:)
      @report = report
      @uploader = uploader
      @errors = []
      @invalid_with_comment = false
    end

    def import(actuals)
      ActiveRecord::Base.transaction do
        @imported_actuals = actuals.map.with_index { |row, index| import_row(row, index) }
        unless @errors.empty?
          @imported_actuals = []
          raise ActiveRecord::Rollback
        end
      end
    end

    def import_row(row, index)
      importer = RowImporter.new(@report, @uploader, row)
      importer.import_row

      importer.errors.each do |attr_name, (value, message)|
        add_error(index, attr_name, value, message)

        @invalid_with_comment ||= row["Comment"].present?
      end

      importer.actual
    end

    def add_error(row_number, column, cell_value, message)
      column_string = (column == :values) ? "Actual Value/Refund Value" : Converter::FIELDS[column]

      @errors << Error.new(row_number, column_string, cell_value, message)
    end

    class RowImporter
      attr_reader :errors, :actual

      def initialize(report, uploader, row)
        @report = report
        @uploader = uploader
        @row = row
        @errors = {}
      end

      def import_row
        @converter = Converter.new(@row)
        @errors.update(@converter.errors)
        return if @converter.zero_value?

        authorise_activity
        @actual = create_actual
      end

      private

      def authorise_activity
        activity_id = @converter.raw(:activity)
        @activity = @converter.activity
        policy = ActivityPolicy.new(@uploader, @activity)

        if @activity.nil?
          @errors[:activity] = [activity_id, I18n.t("importer.errors.actual.unknown_identifier")]
        elsif @activity && !policy.create?
          @errors[:activity] = [activity_id, I18n.t("importer.errors.actual.unauthorised")]
        elsif !reportable_activity?
          @errors[:activity] = [activity_id, I18n.t("importer.errors.actual.unauthorised")]
        end
      end

      def reportable_activity?
        @activity.organisation == @report.organisation && @activity.associated_fund == @report.fund
      end

      def create_actual
        return unless @activity && @errors.empty?

        attrs = @converter.to_h
        assign_default_values(attrs)

        creator = if @converter.actual_class == Refund
          CreateRefund.new(activity: @activity, report: @report, user: @uploader)
        else
          CreateActual.new(activity: @activity, report: @report, user: @uploader)
        end
        result = creator.call(attributes: attrs.except(:refund_value, :actual_value))
        return unless result

        result.object.errors.each do |error|
          @errors[error.attribute] ||= [@converter.raw(error.attribute), error.message]
        end

        result.object
      end

      def assign_default_values(attrs)
        organisation = @activity.providing_organisation

        attrs[:currency] = organisation.default_currency
        presenter = ReportPresenter.new(@report)
        attrs[:description] = "#{presenter.financial_quarter_and_year} spend on #{@activity.title}"
      end
    end

    class Converter
      FIELDS = {
        activity: "Activity RODA Identifier",
        financial_quarter: "Financial Quarter",
        financial_year: "Financial Year",
        actual_value: "Actual Value",
        refund_value: "Refund Value",
        receiving_organisation_name: "Receiving Organisation Name",
        receiving_organisation_type: "Receiving Organisation Type",
        receiving_organisation_reference: "Receiving Organisation IATI Reference",
        comment: "Comment"
      }

      NON_VALUE_FIELDS = FIELDS.without :actual_value, :refund_value

      attr_reader :activity, :errors

      def initialize(row)
        @row = row
        @errors = {}
        @attributes = convert_to_attributes
        @activity = @attributes.delete(:activity)
      end

      # We must have precisely one value, and we will check if
      # the other is empty when we validate the value it contains
      def actual_class
        return Actual if @row["Refund Value"].nil?
        return Refund if @row["Actual Value"].nil? || ConvertFinancialValue.new.convert(@row["Actual Value"]).zero?
      rescue ConvertFinancialValue::Error
      end

      def raw(attr_name)
        @row[FIELDS[attr_name]]
      end

      def to_h
        @attributes
      end

      def convert_to_attributes
        validate_values
        attrs = {value: convert_values}
        NON_VALUE_FIELDS.each_with_object(attrs) do |(attr_name, column_name), attrs|
          attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name])
        end
      end

      def validate_values
        values_string = [
          @row["Actual Value"] || "blank",
          @row["Refund Value"] || "blank"
        ].join(", ")

        types = {
          actual: value_type(value: @row["Actual Value"], field: :actual_value),
          refund: value_type(value: @row["Refund Value"], field: :refund_value)
        }

        error_message = case types
        when {actual: :non_zero, refund: :non_zero}
          I18n.t("importer.errors.actuals_and_refunds.both_present")
        when {actual: :non_zero, refund: :zero}
          I18n.t("importer.errors.refund.cannot_be_zero_when_actual_present")
        when {actual: :zero, refund: :zero}
          I18n.t("importer.errors.actuals_and_refunds.both_zero")
        when {actual: :zero, refund: :blank}
          I18n.t("importer.errors.actual.cannot_be_zero_when_refund_blank")
        when {actual: :blank, refund: :zero}
          I18n.t("importer.errors.refund.cannot_be_zero_when_actual_blank")
        when {actual: :blank, refund: :blank}
          I18n.t("importer.errors.actuals_and_refunds.both_blank")
        end

        @errors[:values] = [values_string, error_message] if error_message
      end

      def value_type(value:, field:)
        return :blank if value.nil?
        converted_value = ConvertFinancialValue.new.convert(value)
        converted_value.zero? ? :zero : :non_zero
      rescue ConvertFinancialValue::Error
        @errors[field] = [value, I18n.t("importer.errors.actuals_and_refunds.non_numeric")]
      end

      def convert_values
        if actual_class == Actual
          convert_to_attribute(:actual_value, @row["Actual Value"])
        else
          convert_to_attribute(:refund_value, @row["Refund Value"])
        end
      end

      def convert_to_attribute(attr_name, attr_value)
        original_value = attr_value.clone
        attr_value = attr_value.to_s.strip

        converter = "convert_#{attr_name}"
        attr_value = __send__(converter, attr_value) if respond_to?(converter)

        attr_value
      rescue Encoding::CompatibilityError
        @errors[attr_name] = [
          original_value.force_encoding("UTF-8"),
          I18n.t("importer.errors.actual.invalid_characters")
        ]
        nil
      rescue => error
        @errors[attr_name] = [original_value, error.message]
        nil
      end

      def convert_activity(id)
        Activity.by_roda_identifier(id)
      end

      def convert_financial_value(value)
        ConvertFinancialValue.new.convert(value)
      rescue ConvertFinancialValue::Error
      end

      alias_method :convert_actual_value, :convert_financial_value
      alias_method :convert_refund_value, :convert_financial_value

      def convert_receiving_organisation_type(type)
        validate_from_codelist(
          type,
          "organisation_type",
          I18n.t("importer.errors.actual.invalid_iati_organisation_type")
        )
      end

      def convert_receiving_organisation_name(name)
        name.presence
      end

      def validate_from_codelist(code, type, message)
        return nil if code.blank?

        codelist = Codelist.new(type: type)

        valid_codes = codelist.map { |entry| entry.fetch("code") }

        raise message unless valid_codes.include?(code)

        code
      end

      def zero_value?
        @attributes[:value].present? && @attributes[:value].zero?
      end
    end
  end
end
