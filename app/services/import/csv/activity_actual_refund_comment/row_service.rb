class Import::Csv::ActivityActualRefundComment::RowService
  attr_reader :errors

  def initialize(report, user, row)
    @report = report
    @user = user
    @activity = nil
    @errors = {}
    @row = Import::Csv::ActivityActualRefundComment::Row.new(row)
  end

  def import!
    if @row.valid?
      @activity = find_activity(@row.roda_identifier)

      return false if @activity.nil?

      return false unless authorise_activity(@activity)

      return Import::Csv::ActivityActualRefundComment::SkippedRow.new(@row) if @row.empty?

      create_record
    else
      @errors.update(@row.errors)
      false
    end
  end

  private def create_record
    case type_of_row(@row)
    when :actual
      result = create_actual(@row, @activity)
    when :refund
      result = create_refund(@row, @activity)
    when :comment
      result = create_activity_comment(@row, @activity)
    end

    return false unless result

    if result.failure?
      result.object.errors.each do |error|
        @errors[error.attribute] = [error.attribute, error.message]
      end
      false
    else
      result.object
    end
  end

  private def find_activity(roda_identifier)
    activity = Activity.find_by_roda_identifier(roda_identifier)

    unless activity
      @errors.update({"Activity RODA Identifier" => [
        roda_identifier, I18n.t("import.csv.activity_actual_refund_comment.errors.activity_roda_identifier.not_found")
      ]})
    end

    activity
  end

  private def authorise_activity(activity)
    policy = ActivityPolicy.new(@user, activity)
    if !policy.create?
      @errors.update({"Activity RODA Identifier" => [
        activity.roda_identifier,
        I18n.t("import.csv.activity_actual_refund_comment.errors.activity_roda_identifier.not_authorised")
      ]})
      return false
    elsif !reportable_activity?(activity)
      @errors.update({"Activity RODA Identifier" => [
        activity.roda_identifier,
        I18n.t("import.csv.activity_actual_refund_comment.errors.activity_roda_identifier.not_reportable")
      ]})
      return false
    end
    true
  end

  private def reportable_activity?(activity)
    activity.organisation == @report.organisation && activity.associated_fund == @report.fund
  end

  private def type_of_row(row)
    return :actual if row.actual_value.positive? && row.refund_value.zero?
    return :refund if row.refund_value.nonzero? && row.actual_value.zero?
    return :comment if row.actual_value.zero? && row.refund_value.zero? && row.comment.present?
  end

  private def create_actual(row, activity)
    creator = CreateActual.new(activity: activity, report: @report, user: @user)
    financial_quarter = FinancialQuarter.new(row.financial_year, row.financial_quarter)

    creator.call(attributes: {
      value: row.actual_value,
      financial_quarter: row.financial_quarter,
      financial_year: row.financial_year,
      comment: row.comment,
      currency: activity.providing_organisation.default_currency,
      description: "#{financial_quarter} spend on #{activity.title}",
      receiving_organisation_name: row.receiving_organisation_name,
      receiving_organisation_type: row.receiving_organisation_type,
      receiving_organisation_reference: row.receiving_organisation_iati_reference
    })
  end

  private def create_refund(row, activity)
    creator = CreateRefund.new(activity: activity, report: @report, user: @user)
    financial_quarter = FinancialQuarter.new(row.financial_year, row.financial_quarter)

    creator.call(attributes: {
      value: row.refund_value,
      financial_quarter: row.financial_quarter,
      financial_year: row.financial_year,
      comment: row.comment,
      currency: activity.providing_organisation.default_currency,
      description: "#{financial_quarter} refund from #{activity.title}",
      receiving_organisation_name: row.receiving_organisation_name,
      receiving_organisation_type: row.receiving_organisation_type,
      receiving_organisation_reference: row.receiving_organisation_iati_reference
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
