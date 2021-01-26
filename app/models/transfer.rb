class Transfer < ApplicationRecord
  belongs_to :source, class_name: "Activity"
  belongs_to :destination, class_name: "Activity"

  validates :source, :destination, :value, :date, presence: true

  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :date, date_not_in_future: true, date_within_boundaries: true
end
