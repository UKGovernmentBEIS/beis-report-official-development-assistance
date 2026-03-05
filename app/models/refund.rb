class Refund < Transaction
  has_one :comment,
    -> { where(commentable_type: "Refund") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true

  validates_associated :comment

  validate :compatibility_of_report_and_activity_oda_wise

  def value=(amount)
    big_decimal = begin
      BigDecimal(amount)
    rescue ArgumentError, TypeError
      return
    end
    write_attribute(:value, -big_decimal.abs)
  end

  private

  def compatibility_of_report_and_activity_oda_wise
    return unless report && parent_activity
    return if report.is_oda? == parent_activity.is_oda?

    errors.add(:base, "A non-ODA report can not include ODA refunds, and vice-versa")
  end
end
