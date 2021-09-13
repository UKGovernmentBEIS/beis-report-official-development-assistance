class Adjustment < Transaction
  has_one :comment,
    -> { where(commentable_type: "Adjustment") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true,
    class_name: "FlexibleComment"

  validates_associated :comment
end
