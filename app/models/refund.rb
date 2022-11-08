class Refund < Transaction
  has_one :comment,
    -> { where(commentable_type: "Refund") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true

  validates_associated :comment

  def value=(amount)
    big_decimal = begin
      BigDecimal(amount)
    rescue ArgumentError, TypeError
      return
    end
    write_attribute(:value, -big_decimal.abs)
  end
end
