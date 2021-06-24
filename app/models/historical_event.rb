class HistoricalEvent < ApplicationRecord
  belongs_to :user
  belongs_to :activity

  serialize :new_value
  serialize :previous_value
end
