class Fund < ApplicationRecord
  validates_presence_of :name
  belongs_to :organisation
  has_one :activity, as: :hierarchy

  scope :for_user, lambda { |user|
    where(organisation: [user.organisations])
  }
end
