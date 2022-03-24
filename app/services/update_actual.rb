class UpdateActual
  def initialize(actual:, user:, report:)
    self.actual = actual
    self.user = user
    self.report = report
  end

  def call(attributes: {})
    comment_body = attributes.delete(:comment).to_s.strip
    assign_comment(comment_body)

    actual.assign_attributes(attributes)

    convert_and_assign_value(actual, attributes[:value])
    changes = actual.changes

    if actual.save
      record_history(changes)
      Result.new(true, actual)
    else
      Result.new(false, actual)
    end
  end

  private

  # Destroy a comment if a blank comment body is provided,
  # otherwise create or update based on the new comment string
  def assign_comment(comment_body)
    if comment_body.blank?
      actual.comment&.destroy
    else
      create_or_update_comment(comment_body)
    end
  end

  def create_or_update_comment(comment_body)
    if actual.comment.present?
      actual.comment.body = comment_body
    else
      actual.build_comment(
        body: comment_body,
        report: actual.report
      )
    end
  end

  def record_history(changes)
    HistoryRecorder
      .new(user: user)
      .call(
        changes: changes,
        reference: "Update to Actual",
        activity: actual.parent_activity,
        trackable: actual,
        report: report
      )
  end

  attr_accessor :actual, :user, :report

  def convert_and_assign_value(actual, value)
    actual.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    actual.errors.add(:value, I18n.t("activerecord.errors.models.actual.attributes.value.not_a_number"))
  end
end
