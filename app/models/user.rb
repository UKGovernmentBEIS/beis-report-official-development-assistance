class User < ApplicationRecord
  has_and_belongs_to_many :organisations
  validates_presence_of :name, :email
end
