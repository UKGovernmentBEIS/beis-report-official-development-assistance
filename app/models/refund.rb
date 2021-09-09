class Refund < Transaction
  has_one :comment,
    -> { where(commentable_type: "Refund") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true,
    class_name: "FlexibleComment"

  validates_associated :comment
end
