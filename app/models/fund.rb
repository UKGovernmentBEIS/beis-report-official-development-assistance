class Fund < ApplicationRecord
  validates_presence_of :name, :organisation_id
  belongs_to :organisation
  has_one :activity

  scope :for_user, lambda { |user|
    where(organisation: [user.organisations])
  }
end
