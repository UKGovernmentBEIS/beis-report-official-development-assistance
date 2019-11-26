class Activity < ApplicationRecord
  belongs_to :hierarchy, polymorphic: true
  validates_presence_of :identifier
  validates_uniqueness_of :identifier
end
