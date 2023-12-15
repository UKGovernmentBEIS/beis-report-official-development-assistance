# This originally handled only Actuals, but now also handles Refunds as well.
class Actual
  class Import
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
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end
    }

    attr_reader :errors, :imported_actuals, :invalid_with_comment

    def self.column_headings
      FIELDS.values
    end

    def initialize(report:, uploader:)
      @report = report
      @uploader = uploader
      @errors = []
    end

    def import(actuals)
      ActiveRecord::Base.transaction do
        @imported_rows = actuals.map.with_index { |row, index| import_row(row, index) }.compact
        @imported_actuals = @imported_rows.select { |row| row.is_a?(Actual) || row.is_a?(Refund) }

        unless @errors.empty?
          @imported_rows = []
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def import_row(row, index)
      importer = RowImporter.new(@report, @uploader, row)
      importer.import_row

      importer.errors.each do |attr_name, (value, message)|
        add_error(index, attr_name, value, message)
      end

      importer.actual
    end

    def add_error(row_number, column, cell_value, message)
      @errors << Error.new(row_number, column, cell_value, message)
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
        row = ::Import::Transactions::ActualAndRefundCsvRow.new(@row)
        row = ::Import::Csv::ActivityActualRefundCommentRow.new(@row)


        if row.valid?
        activity = authorise_activity(row.roda_identifier)
          @actual = create_transaction_from_row(row, activity)
        else
          @errors.update(row.errors)
        end
      end

      private

      def authorise_activity(roda_identifier)
        activity = Activity.find_by_roda_identifier(roda_identifier)
        policy = ActivityPolicy.new(@uploader, activity)

        if activity.nil?
          @errors[:activity] = [roda_identifier, I18n.t("importer.errors.actual.unknown_identifier")]
        elsif activity && !policy.create?
          @errors[:activity] = [roda_identifier, I18n.t("importer.errors.actual.unauthorised")]
        elsif !reportable_activity?(activity)
          @errors[:activity] = [roda_identifier, I18n.t("importer.errors.actual.unauthorised")]
        end
      end

      def reportable_activity?(activity)
        activity.organisation == @report.organisation && activity.associated_fund == @report.fund
      end

      def create_transaction_from_row(row, activity)
        return unless activity && @errors.empty?

        case transaction_type(row)
        when :actual
          creator = CreateActual.new(activity: row.activity, report: @report, user: @uploader)
          result = creator.call(attributes: {
            value: row.actual_value,
            financial_quarter: row.financial_quarter,
            financial_year: row.financial_year,
            comment: comment_for_row(row)
          })
        when :refund
          creator = CreateRefund.new(activity: row.activity, report: @report, user: @uploader)
          result = creator.call(attributes: {
            value: row.refund_value,
            financial_quarter: row.financial_quarter,
            financial_year: row.financial_year,
            comment: comment_for_row(row)
          })
        when :comment
          result = create_activity_comment_for_row(row)
        end

        return unless result

        result.object.errors.each do |error|
          @errors[error.attribute] ||= [error.attribute, error.message]
        end

        result.object
      end

      def create_activity_comment_for_row(row)
        comment = Comment.new(
          body: comment_for_row(row),
          commentable: row.activity,
          owner: @uploader,
          report: @report
        )
        Result.new(comment.save!, comment)
      end

      def assign_default_values(attrs)
        organisation = @activity.providing_organisation

        attrs[:currency] = organisation.default_currency
        presenter = ReportPresenter.new(@report)
        attrs[:description] = "#{presenter.financial_quarter_and_year} spend on #{@activity.title}"
      end

      private def transaction_type(row)
        return :actual if !row.actual_value.zero? && row.refund_value.zero?
        return :refund if !row.refund_value.zero? && row.actual_value.zero?
        return :comment if row.actual_value.zero? && row.refund_value.zero? && row.comment.present?
      end

      private def comment_for_row(row)
        return nil if row.comment.eql?(:blank)

        row.comment
      end
    end
  end
end
