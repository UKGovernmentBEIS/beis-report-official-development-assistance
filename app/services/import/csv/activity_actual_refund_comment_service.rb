class Import::Csv::ActivityActualRefundCommentService
  Error = Struct.new(:row, :column, :value, :message) {
    def csv_row
      row + 2
    end
  }

  attr_reader :errors

  def initialize(report:, user:, csv_rows:)
    @report = report
    @user = user
    @errors = []
    @csv_rows = csv_rows

    @imported_rows = []
  end

  def valid_headers?
    required_headers = [
      "Activity RODA Identifier",
      "Financial Quarter",
      "Financial Year",
      "Actual Value",
      "Refund Value",
      "Comment"
    ]

    required_headers.to_set.subset?(@csv_rows.headers.to_set)
  end

  def import
    raise "Headers not found in file" unless valid_headers?

    ActiveRecord::Base.transaction do
      @imported_rows = @csv_rows.map.with_index do |csv_row, index|
        row = Row.new(@report, @user, csv_row)
        row.import!

        collate_row_errors(index, row)

        row.result.object
      end

      unless @errors.empty?
        raise ActiveRecord::Rollback
      end
    end
  end

  def imported_actuals
    @imported_rows.select do |row|
      row.is_a?(Actual) || row.is_a?(Refund)
    end
  end

  private def collate_row_errors(index, row)
    row.errors.each do |attr_name, (value, message)|
      add_error(index, attr_name, value, message)
    end
  end

  private def add_error(row_number, column, cell_value, message)
    @errors << Error.new(row_number, column, cell_value, message)
  end

  class Row
    attr_reader :errors, :result

    def initialize(report, user, csv_row)
      @report = report
      @user = user
      @csv_row = csv_row
      @errors = {}
    end

    def import!
      row = ::Import::Csv::ActivityActualRefundCommentRow.new(@csv_row)

      if row.valid?
        activity = find_activity(row.roda_identifier)

        unless activity.nil?
          authorise_activity(activity)
        end

        case type_of_row(row)
        when :actual
          @result = create_actual(row, activity)
        when :refund
          @result = create_refund(row, activity)
        when :comment
          @result = create_activity_comment(row, activity)
        end

        return unless result

        @result.object.errors.each do |error|
          @errors[error.attribute] ||= [error.attribute, error.message]
        end

        @result.object
      else
        @errors.update(row.errors)
      end
    end

    private def find_activity(roda_identifier)
      activity = Activity.find_by_roda_identifier(roda_identifier)

      unless activity
        @errors.update({"Activity RODA Identifier" => [roda_identifier, "Cannot be found"]})
      end

      activity
    end

    private def authorise_activity(activity)
      policy = ActivityPolicy.new(@user, activity)
      if !policy.create?
        @errors.update({"Activity RODA Identifier" => [activity.roda_identifier, "Not authorised"]})
      elsif !reportable_activity?(activity)
        @errors.update({"Activity RODA Identifier" => [activity.roda_identifier, "Cannot be included in this report"]})
      end
    end

    private def reportable_activity?(activity)
      activity.organisation == @report.organisation && activity.associated_fund == @report.fund
    end

    private def type_of_row(row)
      return :actual if !row.actual_value.zero? && row.refund_value.zero?
      return :refund if !row.refund_value.zero? && row.actual_value.zero?
      return :comment if row.actual_value.zero? && row.refund_value.zero? && row.comment.present?
    end

    private def create_actual(row, activity)
      creator = CreateActual.new(activity: activity, report: @report, user: @user)

      creator.call(attributes: {
        value: row.actual_value,
        financial_quarter: row.financial_quarter,
        financial_year: row.financial_year,
        comment: row.comment
      })
    end

    private def create_refund(row, activity)
      creator = CreateRefund.new(activity: row.activity, report: @report, user: @user)

      creator.call(attributes: {
        value: row.refund_value,
        financial_quarter: row.financial_quarter,
        financial_year: row.financial_year,
        comment: row.comment
      })
    end

    private def create_activity_comment(row, activity)
      comment = Comment.new(
        body: row.comment,
        commentable: activity,
        owner: @user,
        report: @report
      )

      Result.new(comment.save!, comment)
    end


  end
end
