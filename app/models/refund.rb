class Refund < Transaction
  has_one :comment,
    -> { where(commentable_type: "Refund") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true,
    class_name: "FlexibleComment"

  validates_associated :comment

  attribute :currency, :string, default: "GBP"
  attribute :transaction_type, :string, default: Transaction::TRANSACTION_TYPE_DISBURSEMENT

  def value=(amount)
    big_decimal = begin
                    BigDecimal(amount)
                  rescue ArgumentError, TypeError
                    return
                  end
    write_attribute(:value, -big_decimal.abs)
  end
end
