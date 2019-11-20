class Activity < ApplicationRecord
  belongs_to :fund
  validates_presence_of :identifier
  validates_uniqueness_of :identifier
end
