class Actual < Transaction
  validates :value,
    numericality: {greater_than: 0},
    unless: proc { |actual| actual.validation_context == :history }
end
