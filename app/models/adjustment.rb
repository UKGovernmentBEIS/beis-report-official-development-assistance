class Adjustment < Transaction
  has_one :comment,
    -> { where(commentable_type: "Adjustment") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true

  has_one :detail,
    dependent: :destroy,
    autosave: true,
    class_name: "AdjustmentDetail"

  has_one :creator, through: :detail, source: :user

  validates_associated :comment
  validates_associated :detail
  validate :ensure_correction_suits_adjustment

  delegate :adjustment_type, to: :detail

  def adjustment_type=(variant)
    build_detail unless detail
    detail.adjustment_type = variant
  end

  private

  def ensure_correction_suits_adjustment
    return unless report && financial_quarter && financial_year

    unless financial_period.first < report.financial_period.first
      errors.add(
        :base,
        I18n.t(
          "activerecord.errors.models.adjustment.attributes.financial_period.invalid"
        )
      )
    end
  end
end
