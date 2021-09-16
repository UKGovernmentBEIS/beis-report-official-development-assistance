class HistoricalEvent < ApplicationRecord
  belongs_to :user
  belongs_to :trackable, polymorphic: true
  belongs_to :activity
  belongs_to :report, optional: true

  serialize :new_value
  serialize :previous_value

  before_validation :set_trackable_type, if: -> { trackable.present? }

  def set_trackable_type
    self.trackable_type = trackable.class.to_s
  end
end
