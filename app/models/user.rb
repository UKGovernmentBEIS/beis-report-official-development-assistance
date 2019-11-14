class User < ApplicationRecord
  has_and_belongs_to_many :organisations
  validates_presence_of :name, :email

  enum role: {
    administrator: "administrator",
    delivery_partner: "delivery_partner",
  }

  attribute :role, :string, default: "delivery_partner"
end
