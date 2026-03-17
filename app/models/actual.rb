class Actual < Transaction
  has_one :comment,
    -> { where(commentable_type: "Actual") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true

  validates_associated :comment

  validates :value,
    numericality: {greater_than: 0},
    unless: proc { |actual| actual.validation_context == :history }

  validate :compatibility_of_report_and_activity_oda_wise

  def compatibility_of_report_and_activity_oda_wise
    return unless report && parent_activity
    return if report.is_oda? == parent_activity.is_oda?

    errors.add(:base, "A non-ODA report can not include ODA actuals, and vice-versa")
  end
end
