class Transfer < ApplicationRecord
  belongs_to :source, class_name: "Activity"
  belongs_to :destination, class_name: "Activity"

  belongs_to :report, optional: true

  validates :source, :destination, :value, :financial_year, :financial_quarter, presence: true

  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
end
