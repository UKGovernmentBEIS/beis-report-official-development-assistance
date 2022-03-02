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
end
