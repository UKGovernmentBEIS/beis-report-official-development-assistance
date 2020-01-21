class Programme < ApplicationRecord
  validates_presence_of :name

  belongs_to :organisation
  belongs_to :fund

  has_one :activity, as: :hierarchy
end
