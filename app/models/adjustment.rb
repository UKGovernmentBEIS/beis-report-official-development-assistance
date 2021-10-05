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

  attribute :currency, :string, default: "GBP"
  attribute :transaction_type, :string, default: Transaction::TRANSACTION_TYPE_DISBURSEMENT

  delegate :adjustment_type, to: :detail

  def adjustment_type=(variant)
    build_detail unless detail
    detail.adjustment_type = variant
  end
end
