class HistoricalEvent < ApplicationRecord
  belongs_to :user
  belongs_to :activity
  belongs_to :report, optional: true

  serialize :new_value
  serialize :previous_value
end
