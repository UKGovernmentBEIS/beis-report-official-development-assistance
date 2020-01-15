class Fund < ApplicationRecord
  validates_presence_of :name
  belongs_to :organisation
  has_one :activity, as: :hierarchy
  has_many :programmes
end
